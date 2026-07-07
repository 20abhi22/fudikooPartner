import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/components/descriptionBox.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-edit-model.dart';
import 'package:fudiko/services/individual-menu-upload-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

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
  static const int _maxImageBytes = 10 * 1024 * 1024;
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemDescriptionController =
      TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
  String _imageUploadStatus = '';
  String? existingImageUrl;
  final IndividualMenuUploadService _menuUploadService =
      IndividualMenuUploadService();

  bool _isWideShortPhone(BuildContext context) {
    return Breakpoints.isWideShortPhone(MediaQuery.sizeOf(context));
  }

  bool _isMobileScale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Breakpoints.isMobileDevice(size) && !_isWideShortPhone(context);
  }

  double _contentMaxWidth(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (Breakpoints.isDesktop(size.width)) return 480.0;
    if (Breakpoints.isTabletDevice(size) || _isWideShortPhone(context)) {
      return 460.0;
    }
    return double.infinity;
  }

  double _width(BuildContext context, double value) {
    return _isWideShortPhone(context) ? value : value.w;
  }

  double _height(BuildContext context, double value) {
    return _isWideShortPhone(context) ? value : value.h;
  }

  double _radius(BuildContext context, double value) {
    return _isWideShortPhone(context) ? value : value.r;
  }

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
      isImageUploading = true;
      _imageUploadStatus = 'Uploading image...';
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

      IndividualMenuEditResponseModel response = await _menuUploadService
          .updateMenu(pdfmenu);
      if (response.status) {
        if (!mounted) return;
        _showSuccessMessage('Menu item updated successfully!');
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        _showErrorMessage(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Failed to update menu item: $e');
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
          _imageUploadStatus = '';
        });
      }
    }
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
      final directory = await getTemporaryDirectory();
      final outputFile = File(
        '${directory.path}${Platform.pathSeparator}'
        'menu_edit_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      for (var attempt = 0; attempt < 8; attempt++) {
        final bytes = img.encodeJpg(resizedImage, quality: 85 - (attempt * 5));
        if (bytes.length <= _maxImageBytes) {
          await outputFile.writeAsBytes(bytes, flush: true);
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
    final isWideShortPhone = _isWideShortPhone(context);
    final isMobile = _isMobileScale(context);
    return Scaffold(
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: isWideShortPhone ? 16.0 : _height(context, 35)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWideShortPhone
                      ? 24.0
                      : isMobile
                      ? 30.w
                      : 32.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _contentMaxWidth(context),
                    ),
                    child: Column(
                      children: [
                        _buildImageUploadSection(),
                        SizedBox(
                          height: isWideShortPhone
                              ? 14.0
                              : _height(context, 20),
                        ),
                        _buildFormFields(),
                        SizedBox(
                          height: isWideShortPhone
                              ? 14.0
                              : _height(context, 20),
                        ),
                        _buildCategorySelection(),
                        SizedBox(
                          height: isWideShortPhone
                              ? 20.0
                              : _height(context, 30),
                        ),
                        _buildSubmitButton(),
                        SizedBox(
                          height: isWideShortPhone
                              ? 24.0
                              : _height(context, 20),
                        ),
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
    final isWideShortPhone = _isWideShortPhone(context);
    final size = MediaQuery.sizeOf(context);
    final isTabletLandscape =
        Breakpoints.isTabletDevice(size) && size.width > size.height;
    return Stack(
      children: [
        Image.asset(
          'assets/images/banner1.png',
          height: isWideShortPhone
              ? 120.0
              : isTabletLandscape
              ? 130.0
              : _height(context, MenuUploadConstants.bannerHeight),
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Padding(
          padding: EdgeInsets.all(_width(context, isWideShortPhone ? 24 : 30)),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset(
              backWhite,
              width: _width(context, isWideShortPhone ? 24 : 28),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    final isWideShortPhone = _isWideShortPhone(context);
    final size = MediaQuery.sizeOf(context);
    final isTabletLandscape =
        Breakpoints.isTabletDevice(size) && size.width > size.height;
    return GestureDetector(
      onTap: isImageUploading ? null : _pickImageFile,
      child: Container(
        width: double.infinity,
        height: isWideShortPhone
            ? 110.0
            : isTabletLandscape
            ? 112.0
            : _height(context, MenuUploadConstants.containerHeight),
        padding: EdgeInsets.all(_width(context, 10)),
        decoration: BoxDecoration(
          color: _hasImage() ? Colors.green.shade50 : menuUploadBoxColor,
          borderRadius: BorderRadius.circular(_radius(context, 15)),
          border: _hasImage()
              ? Border.all(color: Colors.green, width: _width(context, 2))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: _radius(context, 10),
              offset: Offset(0, _radius(context, 4)),
            ),
          ],
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
          borderRadius: BorderRadius.circular(_radius(context, 10)),
          child: _buildImageWidget(),
        ),
        SizedBox(width: _width(context, 15)),
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
              SizedBox(height: _height(context, 5)),
              AppText(
                text: "Tap to change image",
                size: 12,
                fontWeight: FontWeight.w400,
                color: appTextColor2,
              ),
              if (existingImageUrl != null && selectedImageFile == null)
                Padding(
                  padding: EdgeInsets.only(top: _height(context, 2)),
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
          icon: Icon(Icons.close, color: Colors.red, size: _width(context, 20)),
        ),
      ],
    );
  }

  // New method to handle both file and network images
  Widget _buildImageWidget() {
    final imageWidth = _width(context, 80);
    final imageHeight = _height(context, 80);
    final errorIconSize = _width(context, 30);

    if (selectedImageFile != null) {
      // Show local file image
      return Image.file(
        selectedImageFile!,
        width: imageWidth,
        height: imageHeight,
        fit: BoxFit.cover,
      );
    } else if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      // Show network image with error handling
      return Image.network(
        existingImageUrl!,
        width: imageWidth,
        height: imageHeight,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: imageWidth,
            height: imageHeight,
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
            width: imageWidth,
            height: imageHeight,
            color: Colors.grey.shade300,
            child: Icon(Icons.error, color: Colors.red, size: errorIconSize),
          );
        },
      );
    }

    return Container(
      width: imageWidth,
      height: imageHeight,
      color: Colors.grey.shade300,
      child: Icon(Icons.image, color: Colors.grey, size: errorIconSize),
    );
  }

  // Image upload placeholder
  Widget _buildImageUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.file_upload_outlined,
          color: Colors.black,
          size: _width(context, 30),
        ),
        SizedBox(height: _height(context, 10)),
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
        SizedBox(height: _height(context, 20)),
        DescriptionTextArea(
          hintText: "Short Description",
          iconImagePath: descriptionIcon,
          iconColor: individualMenuPlaceholderColor,
          maxLines: 3,
          maxLength: MenuUploadConstants.maxDescriptionLength,
          controller: _itemDescriptionController,
        ),
        SizedBox(height: _height(context, 20)),
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
        SizedBox(height: _height(context, 20)),
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
        padding: EdgeInsets.symmetric(
          horizontal: _width(context, 15),
          vertical: _height(context, 8),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? individualMenuchipselectedColor
              : individualMenuchipunselectedColor,
          // border: Border.all(
          //   color: isSelected ? individualMenuchipselectedColor : individualMenuchipunselectedColor,
          //   width: 1.w,
          // ),
          borderRadius: BorderRadius.circular(_radius(context, 15)),
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
      width: _width(context, 200),
      height: _height(context, 50),
      child: AppButton(
        text: isLoading ? "Updating..." : "Update",
        bgColor1: indi_menugradient1,
        bgColor2: indi_menugradient2,
        onPressed: () {
          isLoading ? null : _updateMenu();
        },
        size: 15,
      ),
    );
  }
}
