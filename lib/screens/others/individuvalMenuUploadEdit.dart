import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/components/descriptionBox.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-edit-model.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-upload-model.dart';
import 'package:fudiko/models/menuupload/menu-delete-model.dart';
import 'package:fudiko/screens/others/individualMenuUpload.dart';
import 'package:fudiko/services/individual-menu-upload-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:permission_handler/permission_handler.dart';

class MenuUploadConstants {
  static const double bannerHeight = 150.0;
  static const double containerHeight = 120.0;
  static const int maxDescriptionLength = 350;
  static const List<String> allowedImageExtensions = ['jpg', 'png', 'jpeg'];
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

class IndividualMenuUploadEdit extends StatefulWidget {
  final String menuId;
  final String itemName;
  final String itemPrice;
  final String itemDescription;
  final String itemImage;
  final String itemCategory;
  const IndividualMenuUploadEdit({
    super.key,
    required this.menuId,
    required this.itemName,
    required this.itemPrice,
    required this.itemDescription,
    required this.itemImage,
    required this.itemCategory,
  });

  @override
  State<IndividualMenuUploadEdit> createState() =>
      _IndividualMenuUploadEditState();
}

class _IndividualMenuUploadEditState extends State<IndividualMenuUploadEdit> {
  TextEditingController _itemNameController = TextEditingController();
  TextEditingController _itemDescriptionController = TextEditingController();
  TextEditingController _itemPriceController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<String> foodCategories = [
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

  int selectedCategoryIndex = -1;
  File? selectedImageFile;
  bool isLoading = false;
  bool isImageUploading = false;
  String? existingImageUrl;
  final IndividualMenuUploadService _menuUploadService =
      IndividualMenuUploadService();

  @override
  void initState() {
    setState(() {
      _itemNameController.text = widget.itemName;
      _itemDescriptionController.text = widget.itemDescription;
      _itemPriceController.text = widget.itemPrice;
      selectedCategoryIndex = foodCategories.indexOf(widget.itemCategory);
      if (widget.itemImage.isNotEmpty && !File(widget.itemImage).existsSync()) {
        existingImageUrl = widget.itemImage;
      } else if (widget.itemImage.isNotEmpty) {
        selectedImageFile = File(widget.itemImage);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemDescriptionController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  Future<void> _updateMenu() async {
    if (!_validateForm()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final name = _itemNameController.text.trim();
      final description = _itemDescriptionController.text.trim();
      final price = _itemPriceController.text.trim();
      final category = foodCategories[selectedCategoryIndex];
      final menuid = widget.menuId;
      String imagePath = '';
      if (selectedImageFile != null) {
        imagePath = selectedImageFile!.path;
      } else if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
        imagePath = existingImageUrl!;
      }

      IndividualMenuEditModel pdfmenu = IndividualMenuEditModel(
        imageUrl: imagePath,
        itemName: name,
        itemDescription: description,
        itemPrice: price,
        itemCategory: category,
        menuId: menuid,
      );

      IndividualMenuEditResponseModel response = await _menuUploadService.updateMenu(pdfmenu);
      if(response.status){
        if (!mounted) return;
        _showSuccessMessage('Menu item updated successfully!');
        Navigator.pop(context, true);
      }else{
        if (!mounted) return;
        _showErrorMessage('Menu item update failed!');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Failed to update menu item: $e');
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

    if (!_hasImage()) {
      _showErrorMessage('Please select an image');
      return false;
    }

    return true;
  }

  // Add this helper method to check if there's any image (file or URL)
  bool _hasImage() {
    return selectedImageFile != null ||
        (existingImageUrl != null && existingImageUrl!.isNotEmpty);
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _itemNameController.clear();
    _itemDescriptionController.clear();
    _itemPriceController.clear();
    setState(() {
      selectedCategoryIndex = -1;
      selectedImageFile = null;
      existingImageUrl = null;
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
          existingImageUrl =
              null; // Clear existing URL when new file is selected
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
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
            child: Image.asset(
              backWhite,
              width: 28.w,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return GestureDetector(
      onTap: isImageUploading ? null : _pickImageFile,
      child: Container(
        width: double.infinity,
        height: MenuUploadConstants.containerHeight.h,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: _hasImage() ? Colors.green.shade50 : menuUploadBoxColor,
          borderRadius: BorderRadius.circular(15.r),
          border: _hasImage()
              ? Border.all(color: Colors.green, width: 2.w)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10.r,
              offset: Offset(0, 4.r),
            ),
          ],
        ),
        child: isImageUploading
            ? const Center(child: CircularProgressIndicator())
            : _hasImage()
            ? _buildImagePreview()
            : _buildImageUploadPlaceholder(),
      ),
    );
  }

  // Updated image preview widget to handle both file and network images
  Widget _buildImagePreview() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: _buildImageWidget(),
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
              if (existingImageUrl != null && selectedImageFile == null)
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: AppText(
                    text: "Current image",
                    size: 10,
                    fontWeight: FontWeight.w300,
                    color: Colors.blue,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              selectedImageFile = null;
              existingImageUrl = null;
            });
          },
          icon: Icon(Icons.close, color: Colors.red, size: 20.w),
        ),
      ],
    );
  }

  // New method to handle both file and network images
  Widget _buildImageWidget() {
    if (selectedImageFile != null) {
      // Show local file image
      return Image.file(
        selectedImageFile!,
        width: 80.w,
        height: 80.h,
        fit: BoxFit.cover,
      );
    } else if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      // Show network image with error handling
      return Image.network(
        existingImageUrl!,
        width: 80.w,
        height: 80.h,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 80.w,
            height: 80.h,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 80.w,
            height: 80.h,
            color: Colors.grey.shade300,
            child: Icon(Icons.error, color: Colors.red, size: 30.w),
          );
        },
      );
    }

    return Container(
      width: 80.w,
      height: 80.h,
      color: Colors.grey.shade300,
      child: Icon(Icons.image, color: Colors.grey, size: 30.w),
    );
  }

  // Image upload placeholder
  Widget _buildImageUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.file_upload_outlined, color: Colors.black, size: 30.w),
        SizedBox(height: 10.h),
        AppText(
          text: "Click here to choose",
          size: 15,
          fontWeight: FontWeight.w400,
          color: appTextColor2,
        ),
        AppText(
          text: "your image",
          size: 15,
          fontWeight: FontWeight.w400,
          color: appTextColor2,
        ),
      ],
    );
  }

  // Form fields section
  Widget _buildFormFields() {
    return Column(
      children: [
        AppTextFeild(
          text: "Item Name",
          iconImagePath: riceBowlIcon,
          iconColor: individualMenuPlaceholderColor,
          controller: _itemNameController,
        ),
        SizedBox(height: 20.h),
        DescriptionTextArea(
          hintText: "Short Description",
          iconImagePath: descriptionIcon,
          iconColor: individualMenuPlaceholderColor,
          maxLines: 3,
          maxLength: MenuUploadConstants.maxDescriptionLength,
          controller: _itemDescriptionController,
        ),
        SizedBox(height: 20.h),
        AppTextFeild(
          text: "Price",
          iconImagePath: dollarIcon,
          iconColor: individualMenuPlaceholderColor,
          controller: _itemPriceController,
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
              size: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            foodCategories.length,
            (index) => _buildCategoryChip(
              foodCategories[index],
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
      width: 200.w,
      height: 50.h,
      child: AppButton(
        text: isLoading ? "Updating..." : "Update",
         bgColor1:indi_menugradient1,
          bgColor2: indi_menugradient2,
        onPressed: () {
          isLoading ? null : _updateMenu();
        },
        size: 15,
      ),
    );
  }
}
