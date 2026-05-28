import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/components/descriptionBox.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-upload-model.dart';
import 'package:fudiko/models/menuupload/menu-delete-model.dart';
import 'package:fudiko/screens/others/individualMenuUpload.dart';
import 'package:fudiko/services/individual-menu-upload-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:permission_handler/permission_handler.dart';

class MenuUploadConstants {
  static const double bannerHeight = 150.0;
  static const double containerHeight = 130.0;
  static const int maxDescriptionLength = 350;
  static const List<String> allowedImageExtensions = ['jpg', 'png', 'jpeg'];
  static const List<String> foodCategories = [
    "Starter",
    "Main Course",
    "Salad",
    "Drink",
    "Slides",
    "Grill & BBQ",
    "Desserts",
    "Continental",
    "Soups",
  ];
}

class MenuItemValidator {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Item name is required';
    }
    if (value.trim().length < 2) {
      return 'Item name must be at least 2 characters';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value.trim());
    if (price == null) {
      return 'Please enter a valid price';
    }
    if (price <= 0) {
      return 'Price must be greater than 0';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }
}

class IndividualMenuUpload2 extends StatefulWidget {
  const IndividualMenuUpload2({super.key});

  @override
  State<IndividualMenuUpload2> createState() => _IndividualMenuUpload2State();
}

class _IndividualMenuUpload2State extends State<IndividualMenuUpload2> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemWeightController = TextEditingController();
  final TextEditingController _itemDescriptionController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int selectedCategoryIndex = -1;
  File? selectedImageFile;
  bool isLoading = false;
  bool isImageUploading = false;

  final IndividualMenuUploadService _menuUploadService = IndividualMenuUploadService();

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemWeightController.dispose();
    _itemDescriptionController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  Future<void> _createMenu() async {
    if (!_validateForm()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final name =  _itemNameController.text.trim();
      final description = _itemDescriptionController.text.trim();
      final price = _itemPriceController.text.trim();
      final category = MenuUploadConstants.foodCategories[selectedCategoryIndex];
      final image = selectedImageFile;


      IndividualMenuUploadModel pdfmenu = IndividualMenuUploadModel(itemName: name, itemPrice: price, itemDescription: description, itemImage: image!.path, itemCategory: category);
      IndividualMenuUploadResponseModel response = await _menuUploadService.createMenu(pdfmenu);

      if(response.status){
        if (!mounted) return;
        _showSuccessMessage('Menu item added successfully!');
        _resetForm();
      }else{
        if (!mounted) return;
        _showSuccessMessage('Menu item upload failed!');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Failed to add menu item: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (selectedCategoryIndex == -1) {
      _showErrorMessage('Please select a category');
      return false;
    }

    if (selectedImageFile == null) {
      _showErrorMessage('Please select an image');
      return false;
    }

    return true;
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _itemNameController.clear();
    _itemDescriptionController.clear();
    _itemPriceController.clear();
    setState(() {
      selectedCategoryIndex = -1;
      selectedImageFile = null;
    });
  }

  Future<void> _pickImageFile() async {
    try {
      setState(() {
        isImageUploading = true;
      });

      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        _showErrorMessage('Storage permission is required to select images');
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: MenuUploadConstants.allowedImageExtensions,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          _showErrorMessage('Image size should be less than 5MB');
          return;
        }

        setState(() {
          selectedImageFile = file;
        });

        _showSuccessMessage('Image selected successfully!');
      }
    } catch (e) {
      _showErrorMessage('Failed to select image: $e');
    } finally {
      if (mounted) {
        setState(() {
          isImageUploading = false;
        });
      }
    }
  }

  // Permission handling
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      final manageStatus = await Permission.manageExternalStorage.request();
      final storageStatus = await Permission.storage.request();

      return manageStatus.isGranted || storageStatus.isGranted;
    }
    return true;
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 35.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                child: Column(
                  children: [
                    _buildImageUploadSection(),
                    SizedBox(height: 20.h),
                    _buildFormFields(),
                    SizedBox(height: 20.h),
                    _buildCategorySelection(),
                    SizedBox(height: 30.h),
                    _buildSubmitButton(),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header with banner and back button
  Widget _buildHeader() {
    return Stack(
      children: [
        Image.asset(
          'assets/images/banner1.png',
          height: MenuUploadConstants.bannerHeight.h,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Padding(
          padding: EdgeInsets.all(30.w),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: 
            Image.asset(
              backWhite,
              width: 32.w,
              height: 32.h,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  // Image upload section with preview
  Widget _buildImageUploadSection() {
    return GestureDetector(
      onTap: isImageUploading ? null : _pickImageFile,
      child: Container(
        width: double.infinity,
        height: MenuUploadConstants.containerHeight.h,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: selectedImageFile != null ? Colors.green.shade50 : individualmenuUploadBoxColor,
          borderRadius: BorderRadius.circular(20.r),
          border: selectedImageFile != null
              ? Border.all(color: Colors.green, width: 2.w)
              : null,
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.1),
          //     blurRadius: 10.r,
          //     offset: Offset(0, 4.r),
          //   ),
          // ],
        ),
        child: isImageUploading
            ? const Center(child: CircularProgressIndicator())
            : selectedImageFile != null
            ? _buildImagePreview()
            : _buildImageUploadPlaceholder(),
      ),
    );
  }

  // Image preview widget
  Widget _buildImagePreview() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Image.file(
            selectedImageFile!,
            width: 80.w,
            height: 80.h,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: "Image Selected",
                size: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
              SizedBox(height: 5.h),
              AppText(
                text: "Tap to change image",
                size: 12,
                fontWeight: FontWeight.w400,
                color: appTextColor2,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              selectedImageFile = null;
            });
          },
          icon: Icon(
            Icons.close,
            color: Colors.red,
            size: 20.w,
          ),
        ),
      ],
    );
  }

  // Image upload placeholder
  Widget _buildImageUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(  
          uploadIcon,
          width: 28.w,
          height: 28.h,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 10.h),
        AppText(
          text: "Click here to add  your",
          size: 10.sp,
          fontWeight: FontWeight.w400,
          color: appTextColor2.withOpacity(0.63),
        ),
        AppText(
          text: "your image",
          size: 10.sp,
          fontWeight: FontWeight.w400,
          color: appTextColor2.withOpacity(0.63),
        ),
      ],
    );
  }

  // Form fields section
  Widget _buildFormFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextFeild(
                text: "Item Name",
                iconImagePath: riceBowlIcon,
                iconColor: individualMenuPlaceholderColor,
                controller: _itemNameController,
                isRequired: true,
                validator: MenuItemValidator.validateName,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 18,
                    spreadRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        AppTextFeild(
          text: " Weight",
          iconImagePath: weighIcon,
          iconColor: individualMenuPlaceholderColor,
          controller: _itemWeightController,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              if (double.tryParse(value.trim()) == null) {
                return 'Please enter a valid weight';
              }
            }
            return null;
          },
        ),
        SizedBox(height: 20.h),
        DescriptionTextArea(
          hintText: "Short Description",
          iconImagePath: descriptionIcon,
          iconColor: individualMenuPlaceholderColor,
          maxLines: 5,
          maxLength: MenuUploadConstants.maxDescriptionLength,
          controller: _itemDescriptionController,
          validator: MenuItemValidator.validateDescription,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        AppTextFeild(
          text: "Price",
          iconImagePath: dollarIcon,
          iconColor: individualMenuPlaceholderColor,
          controller: _itemPriceController,
          isRequired: true,
          validator: MenuItemValidator.validatePrice,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ],
    );
  }

  // Category selection section
  Widget _buildCategorySelection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              text: "Select Your Item Category",
              size: 10.sp,
              fontWeight: FontWeight.w400,
              color: appTextColor5,
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            MenuUploadConstants.foodCategories.length,
                (index) => _buildCategoryChip(
              MenuUploadConstants.foodCategories[index],
              selectedCategoryIndex == index,
                  () {
                setState(() {
                  selectedCategoryIndex = index;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // Individual category selection chip
  Widget _buildCategoryChip(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? individualMenuchipselectedColor : individualMenuchipunselectedColor,
          // border: Border.all(
          //   color: isSelected ? individualMenuchipselectedColor : individualMenuchipunselectedColor,
          //   width: 1.w,
          // ),
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: AppText(
          text: text,
           color: isSelected ? Colors.white : Colors.black,
            size: 12,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w500,
        ),
      ),
    );
  }

  // Submit button with loading state
  Widget _buildSubmitButton() {
    return SizedBox(
      width: 160.w,
      height: 48.h,
      child: AppButton(
        bgColor1:indi_menugradient1,
        borderRadius: 15,
        bgColor2: indi_menugradient2,
        text: isLoading ? "Adding..." : "Add",
        onPressed: (){
          isLoading ? null : _createMenu();
        },
        size: 17.sp,
      ),
    );
  }
}