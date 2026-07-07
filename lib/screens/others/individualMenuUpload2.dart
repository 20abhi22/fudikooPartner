import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/components/descriptionBox.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-upload-model.dart';
import 'package:fudiko/services/individual-menu-upload-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

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
  static const int _maxImageBytes = 10 * 1024 * 1024;
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemWeightController = TextEditingController();
  final TextEditingController _itemDescriptionController =
      TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int selectedCategoryIndex = -1;
  File? selectedImageFile;
  bool isLoading = false;
  bool isImageUploading = false;
  String _imageUploadStatus = '';

  final IndividualMenuUploadService _menuUploadService =
      IndividualMenuUploadService();

  bool _isWideShortPhone(BuildContext context) {
    return Breakpoints.isWideShortPhone(MediaQuery.sizeOf(context));
  }

  bool _isMobile(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Breakpoints.isMobileDevice(size) && !_isWideShortPhone(context);
  }

  double _contentMaxWidth(Size size, bool isWideShortPhone) {
    final width = size.width;
    if (Breakpoints.isDesktop(width)) return 480;
    if (Breakpoints.isTabletDevice(size) || isWideShortPhone) return 460;
    return double.infinity;
  }

  EdgeInsetsGeometry _contentPadding(Size size, bool isWideShortPhone) {
    final width = size.width;
    if (isWideShortPhone) {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    }
    final isMobile = Breakpoints.isMobileDevice(size);
    return EdgeInsets.symmetric(
      horizontal: isMobile ? 30.w : AppDimensions.padding(width),
    );
  }

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
      isImageUploading = true;
      _imageUploadStatus = 'Uploading image...';
    });

    try {
      final name = _itemNameController.text.trim();
      final description = _itemDescriptionController.text.trim();
      final price = _itemPriceController.text.trim();
      final category =
          MenuUploadConstants.foodCategories[selectedCategoryIndex];
      final image = selectedImageFile;

      IndividualMenuUploadModel pdfmenu = IndividualMenuUploadModel(
        itemName: name,
        itemPrice: price,
        itemDescription: description,
        itemImage: image!.path,
        itemCategory: category,
      );
      IndividualMenuUploadResponseModel response = await _menuUploadService
          .createMenu(pdfmenu);

      if (response.status) {
        if (!mounted) return;
        _showSuccessMessage('Menu item added successfully!');
        _resetForm();
      } else {
        if (!mounted) return;
        _showErrorMessage(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Failed to add menu item: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isImageUploading = false;
          _imageUploadStatus = '';
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
        setState(() => _imageUploadStatus = 'Compressing image...');
        final uploadFile = await _prepareImageForUpload(file);
        if (uploadFile == null) return;

        setState(() {
          selectedImageFile = uploadFile;
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
    final size = MediaQuery.sizeOf(context);
    final isWideShortPhone = _isWideShortPhone(context);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final headerGap = isWideShortPhone
        ? 16.0
        : isMobile
        ? 35.h
        : 32.0;
    final fieldGap = isWideShortPhone
        ? 14.0
        : isMobile
        ? 20.h
        : 20.0;
    final categoryGap = isWideShortPhone
        ? 20.0
        : isMobile
        ? 30.h
        : 30.0;
    final bottomGap = isWideShortPhone
        ? 24.0
        : isMobile
        ? 20.h
        : 40.0;

    return Scaffold(
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: headerGap),
              Padding(
                padding: _contentPadding(size, isWideShortPhone),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _contentMaxWidth(size, isWideShortPhone),
                    ),
                    child: Column(
                      children: [
                        _buildImageUploadSection(),
                        SizedBox(height: fieldGap),
                        _buildFormFields(),
                        SizedBox(height: fieldGap),
                        _buildCategorySelection(),
                        SizedBox(height: categoryGap),
                        _buildSubmitButton(),
                        SizedBox(height: bottomGap),
                      ],
                    ),
                  ),
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
    final isMobile = _isMobile(context);
    final isWideShortPhone = _isWideShortPhone(context);
    final size = MediaQuery.sizeOf(context);
    final isTabletLandscape =
        Breakpoints.isTabletDevice(size) && size.width > size.height;
    final bannerHeight = isWideShortPhone
        ? 120.0
        : isTabletLandscape
        ? 130.0
        : isMobile
        ? MenuUploadConstants.bannerHeight.h
        : 160.0;
    final backPadding = isWideShortPhone
        ? 24.0
        : isMobile
        ? 30.w
        : AppDimensions.padding(size.width);
    final backIconSize = isWideShortPhone
        ? 24.0
        : isMobile
        ? 32.w
        : 32.0;

    return Stack(
      children: [
        Image.asset(
          'assets/images/banner1.png',
          height: bannerHeight,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Padding(
          padding: EdgeInsets.all(backPadding),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset(
              backWhite,
              width: backIconSize,
              height: backIconSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  // Image upload section with preview
  Widget _buildImageUploadSection() {
    final isMobile = _isMobile(context);
    final isWideShortPhone = _isWideShortPhone(context);
    final containerHeight = isWideShortPhone
        ? 110.0
        : isMobile
        ? MenuUploadConstants.containerHeight.h
        : MenuUploadConstants.containerHeight;
    final boxPadding = isWideShortPhone
        ? 10.0
        : isMobile
        ? 10.w
        : 10.0;
    final boxRadius = isWideShortPhone
        ? 16.0
        : isMobile
        ? 20.r
        : 20.0;
    final borderWidth = isWideShortPhone
        ? 2.0
        : isMobile
        ? 2.w
        : 2.0;

    return GestureDetector(
      onTap: isImageUploading ? null : _pickImageFile,
      child: Container(
        width: double.infinity,
        height: containerHeight,
        padding: EdgeInsets.all(boxPadding),
        decoration: BoxDecoration(
          color: selectedImageFile != null
              ? Colors.green.shade50
              : individualmenuUploadBoxColor,
          borderRadius: BorderRadius.circular(boxRadius),
          border: selectedImageFile != null
              ? Border.all(color: Colors.green, width: borderWidth)
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
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      _imageUploadStatus.isEmpty
                          ? 'Processing image...'
                          : _imageUploadStatus,
                    ),
                  ],
                ),
              )
            : selectedImageFile != null
            ? _buildImagePreview()
            : _buildImageUploadPlaceholder(),
      ),
    );
  }

  // Image preview widget
  Widget _buildImagePreview() {
    final isMobile = _isMobile(context);
    final previewRadius = isMobile ? 10.r : 10.0;
    final previewSize = isMobile ? 80.w : 80.0;
    final previewGap = isMobile ? 15.w : 15.0;
    final textGap = isMobile ? 5.h : 5.0;
    final closeIconSize = isMobile ? 20.w : 20.0;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(previewRadius),
          child: Image.file(
            selectedImageFile!,
            width: previewSize,
            height: previewSize,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: previewGap),
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
              SizedBox(height: textGap),
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
          icon: Icon(Icons.close, color: Colors.red, size: closeIconSize),
        ),
      ],
    );
  }

  // Image upload placeholder
  Widget _buildImageUploadPlaceholder() {
    final isMobile = _isMobile(context);
    final iconSize = isMobile ? 28.w : 28.0;
    final gap = isMobile ? 10.h : 10.0;
    final textSize = isMobile ? 10.sp : 10.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          uploadIcon,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
        ),
        SizedBox(height: gap),
        AppText(
          text: "Click here to add  your",
          size: textSize,
          fontWeight: FontWeight.w400,
          color: appTextColor2.withValues(alpha: 0.63),
        ),
        AppText(
          text: "your image",
          size: textSize,
          fontWeight: FontWeight.w400,
          color: appTextColor2.withValues(alpha: 0.63),
        ),
      ],
    );
  }

  // Form fields section
  Widget _buildFormFields() {
    final isMobile = _isMobile(context);
    final fieldGap = isMobile ? 20.h : 20.0;
    final fieldTextSize = isMobile ? 16.0 : 14.0;

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
                size: fieldTextSize,
                validator: MenuItemValidator.validateName,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    spreadRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: fieldGap),
        AppTextFeild(
          text: " Weight",
          iconImagePath: weighIcon,
          iconColor: individualMenuPlaceholderColor,
          controller: _itemWeightController,
          size: fieldTextSize,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
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
        SizedBox(height: fieldGap),
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
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        SizedBox(height: fieldGap),
        AppTextFeild(
          text: "Price",
          iconImagePath: dollarIcon,
          iconColor: individualMenuPlaceholderColor,
          controller: _itemPriceController,
          isRequired: true,
          size: fieldTextSize,
          validator: MenuItemValidator.validatePrice,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
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
    final isMobile = _isMobile(context);
    final titleSize = isMobile ? 10.sp : 10.0;
    final titleGap = isMobile ? 20.h : 20.0;
    final chipSpacing = isMobile ? 10.0 : 10.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              text: "Select Your Item Category",
              size: titleSize,
              fontWeight: FontWeight.w400,
              color: appTextColor5,
            ),
          ],
        ),
        SizedBox(height: titleGap),
        Wrap(
          spacing: chipSpacing,
          runSpacing: chipSpacing,
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
    final isMobile = _isMobile(context);
    final horizontalPadding = isMobile ? 15.w : 15.0;
    final verticalPadding = isMobile ? 8.h : 8.0;
    final chipRadius = isMobile ? 15.r : 15.0;
    final chipTextSize = isMobile ? 12.0 : 12.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? individualMenuchipselectedColor
              : individualMenuchipunselectedColor,
          // border: Border.all(
          //   color: isSelected ? individualMenuchipselectedColor : individualMenuchipunselectedColor,
          //   width: 1.w,
          // ),
          borderRadius: BorderRadius.circular(chipRadius),
        ),
        child: AppText(
          text: text,
          color: isSelected ? Colors.white : Colors.black,
          size: chipTextSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Submit button with loading state
  Widget _buildSubmitButton() {
    final isMobile = _isMobile(context);
    final buttonWidth = isMobile ? 160.w : 160.0;
    final buttonHeight = isMobile ? 48.h : 48.0;
    final buttonTextSize = isMobile ? 17.sp : 17.0;

    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: AppButton(
        bgColor1: indi_menugradient1,
        borderRadius: 15,
        bgColor2: indi_menugradient2,
        text: isLoading ? "Adding..." : "Add",
        onPressed: () {
          if (!isLoading) {
            _createMenu();
          }
        },
        size: buttonTextSize,
      ),
    );
  }

  Future<File?> _prepareImageForUpload(File imageFile) async {
    if (await imageFile.length() <= _maxImageBytes) return imageFile;

    try {
      final decodedImage = img.decodeImage(await imageFile.readAsBytes());
      if (decodedImage == null) {
        _showErrorMessage('Unable to process this image. Choose a JPG or PNG.');
        return null;
      }

      var resizedImage = decodedImage;
      final temporaryDirectory = await getTemporaryDirectory();
      final outputFile = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}'
        'menu_upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      for (var attempt = 0; attempt < 8; attempt++) {
        final compressedBytes = img.encodeJpg(
          resizedImage,
          quality: 85 - (attempt * 5),
        );
        if (compressedBytes.length <= _maxImageBytes) {
          await outputFile.writeAsBytes(compressedBytes, flush: true);
          return outputFile;
        }
        final nextWidth = (resizedImage.width * 0.8).round();
        if (nextWidth < 320) break;
        resizedImage = img.copyResize(resizedImage, width: nextWidth);
      }
    } catch (_) {}

    _showErrorMessage('Unable to compress the image below the 10 MB limit');
    return null;
  }
}
