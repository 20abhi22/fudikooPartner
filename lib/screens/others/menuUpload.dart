import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/menuupload/menu-delete-model.dart';
import 'package:fudiko/models/menuupload/menu-list-model.dart';
import 'package:fudiko/models/menuupload/menu-update-model.dart';
import 'package:fudiko/models/menuupload/menu-upload-model.dart';
import 'package:fudiko/services/menu-upload-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/translator_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

bool _isWideShortPhone(BuildContext context) {
  return Breakpoints.isWideShortPhone(MediaQuery.sizeOf(context));
}

class MenuUpload extends StatefulWidget {
  const MenuUpload({super.key});

  @override
  State<MenuUpload> createState() => _MenuUploadState();
}

class _UploadPdfPrompt extends StatefulWidget {
  const _UploadPdfPrompt();

  @override
  State<_UploadPdfPrompt> createState() => _UploadPdfPromptState();
}

class _UploadPdfPromptState extends State<_UploadPdfPrompt> {
  String _uploadText = 'Upload Menu as';
  String _documentText = 'Document';

  @override
  void initState() {
    super.initState();
    _translate();
  }

  Future<void> _translate() async {
    final results = await Future.wait([
      TranslatorService.translate('Upload Menu as'),
      TranslatorService.translate('Document'),
    ]);

    if (!mounted) return;
    setState(() {
      _uploadText = results[0];
      _documentText = results[1];
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWideShortPhone = _isWideShortPhone(context);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: isMobile ? 14.sp : 14.0,
          fontWeight: FontWeight.w400,
          color: appTextColor2.withValues(alpha: 0.75),
          height: 1.25,
        ),
        children: [
          TextSpan(text: '$_uploadText '),
          const TextSpan(
            text: 'PDF',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: '\n$_documentText'),
        ],
      ),
    );
  }
}

class _MenuUploadState extends State<MenuUpload> {
  static const int _maxPdfBytes = 10 * 1024 * 1024;
  bool isOpen = false;
  bool isLoading = false;
  bool isEditMode = false;
  bool isUploading = false;
  String _uploadStatus = '';
  File? selectedPdfFile;
  List<MenuModel> menus = [];
  MenuModel? editingMenu;
  final TextEditingController fileNameController = TextEditingController();
  MenuUploadService menuUploadService = MenuUploadService();

  double _contentMaxWidth(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    if (Breakpoints.isDesktop(width)) return 760;
    if (Breakpoints.isTabletDevice(size) || _isWideShortPhone(context)) {
      return 680;
    }
    return double.infinity;
  }

  EdgeInsetsGeometry _pagePadding(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    if (_isWideShortPhone(context)) {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    }
    final isMobile = Breakpoints.isMobileDevice(size);
    return EdgeInsets.symmetric(
      horizontal: isMobile ? 20.w : AppDimensions.padding(width),
    );
  }

  Widget _responsiveContent({
    required Widget child,
    double? maxWidth,
    EdgeInsetsGeometry? padding,
    Alignment alignment = Alignment.topCenter,
  }) {
    return Padding(
      padding: padding ?? _pagePadding(context),
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? _contentMaxWidth(context),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<void> uploadMenu() async {
    if (selectedPdfFile == null || fileNameController.text.isEmpty) {
      _showSnackBar('Please select a file and enter a menu name');
      return;
    }
    setState(() {
      isUploading = true;
      _uploadStatus = 'Uploading PDF...';
    });
    try {
      MenuUploadModel menu = MenuUploadModel(
        file: selectedPdfFile!,
        menuName: fileNameController.text.trim(),
      );
      MenuUploadResponseModel response = await menuUploadService.addMenu(menu);
      if (!mounted) return;
      _showSnackBar(response.message);
      if (response.status) {
        getAllPdfs();
        closeModal();
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Upload failed: ${e.toString()}');
    } finally {
      if (mounted)
        setState(() {
          isUploading = false;
          _uploadStatus = '';
        });
    }
  }

  Future<void> updateMenu() async {
    if (editingMenu == null || fileNameController.text.isEmpty) {
      _showSnackBar('Invalid menu data');
      return;
    }
    setState(() {
      isUploading = true;
      _uploadStatus = 'Updating PDF...';
    });
    try {
      MenuUpdateModel menu = MenuUpdateModel(
        menuId: editingMenu!.uuid,
        menuName: fileNameController.text.trim(),
        pdfFilePath: selectedPdfFile?.path,
      );
      MenuUpdateResponseModel response = await menuUploadService.updateMenu(
        menu,
      );
      if (!mounted) return;
      _showSnackBar(
        response.status ? 'Menu updated successfully' : response.message,
      );
      if (response.status) {
        getAllPdfs();
        closeModal();
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Update failed: ${e.toString()}');
    } finally {
      if (mounted)
        setState(() {
          isUploading = false;
          _uploadStatus = '';
        });
    }
  }

  Future<void> pdfEdit(MenuModel menu) async {
    setState(() {
      isEditMode = true;
      editingMenu = menu;
      fileNameController.text = menu.menuName;
      selectedPdfFile = null;
      isOpen = true;
    });
  }

  void openAddModal() {
    setState(() {
      isEditMode = false;
      editingMenu = null;
      selectedPdfFile = null;
      fileNameController.text = "";
      isOpen = true;
    });
  }

  void closeModal() {
    setState(() {
      isOpen = false;
      isEditMode = false;
      editingMenu = null;
      selectedPdfFile = null;
      fileNameController.clear();
      isUploading = false;
    });
  }

  Future<void> getAllPdfs() async {
    setState(() => isLoading = true);
    try {
      MenuListModel menuList = await menuUploadService.getAllPdfMenus();
      if (mounted) {
        setState(() {
          menus = menuList.menus;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar('Failed to load menus: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    getAllPdfs();
  }

  @override
  void dispose() {
    fileNameController.dispose();
    super.dispose();
  }

  Future<void> pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        if (await file.length() > _maxPdfBytes) {
          _showSnackBar('PDF is too large. The maximum size is 10 MB.');
          return;
        }
        setState(() {
          selectedPdfFile = file;
          if (!isEditMode || fileNameController.text.isEmpty) {
            fileNameController.text = selectedPdfFile!.path
                .split('/')
                .last
                .replaceFirst('.pdf', '');
          }
        });
      } else {
        setState(() {
          selectedPdfFile = null;
          if (!isEditMode) fileNameController.clear();
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick file: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWideShortPhone = _isWideShortPhone(context);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final isTabletLandscape =
        Breakpoints.isTabletDevice(size) && width > size.height;
    final bannerHeight = isWideShortPhone
        ? 120.0
        : isTabletLandscape
        ? 130.0
        : isMobile
        ? 150.h
        : 160.0;
    final backPadding = isWideShortPhone
        ? 24.0
        : isMobile
        ? 30.w
        : AppDimensions.padding(width);
    final backIconSize = isWideShortPhone
        ? 24.0
        : isMobile
        ? 28.w
        : 28.0;
    final contentGap = isWideShortPhone
        ? 12.0
        : isMobile
        ? 20.h
        : 24.0;
    final emptyIconSize = isWideShortPhone
        ? 52.0
        : isMobile
        ? 60.w
        : 60.0;
    final emptyGap = isWideShortPhone
        ? 8.0
        : isMobile
        ? 10.h
        : 10.0;
    final emptyTextSize = isWideShortPhone
        ? 14.0
        : isMobile
        ? 14.sp
        : 14.0;
    final fabSize = isWideShortPhone
        ? 60.0
        : isMobile
        ? 75.w
        : 72.0;
    final fabBottom = isWideShortPhone
        ? 24.0
        : isMobile
        ? 40.h
        : 40.0;
    final fabRight = isWideShortPhone
        ? 24.0
        : isMobile
        ? 20.w
        : AppDimensions.padding(width);
    final modalHorizontalPadding = isWideShortPhone
        ? 36.0
        : isMobile
        ? 24.w
        : AppDimensions.padding(width);
    final modalWidth = isWideShortPhone
        ? 420.0
        : isMobile
        ? double.infinity
        : 430.0;
    final modalPaddingH = isWideShortPhone
        ? 20.0
        : isMobile
        ? 20.w
        : 20.0;
    final modalPaddingV = isWideShortPhone
        ? 18.0
        : isMobile
        ? 24.h
        : 24.0;
    final modalRadius = isWideShortPhone
        ? 16.0
        : isMobile
        ? 20.r
        : 20.0;
    final modalGapSmall = isWideShortPhone
        ? 6.0
        : isMobile
        ? 8.h
        : 8.0;
    final modalGapMedium = isWideShortPhone
        ? 14.0
        : isMobile
        ? 18.h
        : 18.0;
    final modalGapLarge = isWideShortPhone
        ? 18.0
        : isMobile
        ? 22.h
        : 22.0;
    final pickerPaddingH = isWideShortPhone
        ? 18.0
        : isMobile
        ? 20.w
        : 20.0;
    final pickerPaddingV = isWideShortPhone
        ? 18.0
        : isMobile
        ? 22.h
        : 22.0;
    final pickerRadius = isWideShortPhone
        ? 14.0
        : isMobile
        ? 15.r
        : 15.0;
    final uploadIconSize = isWideShortPhone
        ? 28.0
        : isMobile
        ? 32.w
        : 32.0;
    final actionButtonWidth = isWideShortPhone
        ? 120.0
        : isMobile
        ? 130.w
        : 130.0;
    final actionButtonHeight = isWideShortPhone
        ? 40.0
        : isMobile
        ? 40.h
        : 40.0;
    final actionTextSize = isWideShortPhone
        ? 13.0
        : isMobile
        ? 13.sp
        : 13.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // ── Main content ─────────────────────────────────────────
            Column(
              children: [
                // Banner with back button
                Stack(
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
                          fit: BoxFit.contain,
                        ),
                        // child: Icon(
                        //   Icons.arrow_back_ios_outlined,
                        //   size: 30.w,
                        //   color: Colors.white,
                        // ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: contentGap),
                if (isLoading)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: appButtonColor),
                    ),
                  )
                else if (menus.isNotEmpty)
                  Expanded(
                    child: _responsiveContent(
                      padding: _pagePadding(context),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: menus.length,
                        itemBuilder: (context, index) => _pdfBox(menus[index]),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: emptyIconSize,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: emptyGap),
                          Text(
                            "No PDF Available",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: emptyTextSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // ── FAB ──────────────────────────────────────────────────
            Positioned(
              bottom: fabBottom,
              right: fabRight,
              child: GestureDetector(
                onTap: isUploading ? null : openAddModal,
                child: Container(
                  width: fabSize,
                  height: fabSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // uses your appButtonColor (orange) from constants
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF000000).withOpacity(0.35),
                        offset: const Offset(0, 0), // X: 0, Y: 0
                        blurRadius: 10, // Blur: 10
                        spreadRadius: 0, // Spread: 0
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Image.asset(
                      plusIcon,
                      width: isMobile ? 10.w : 10.0,
                      height: isMobile ? 10.h : 10.0,
                      // fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // ── Modal overlay ─────────────────────────────────────────
            if (isOpen) ...[
              // Backdrop
              GestureDetector(
                onTap: isUploading ? null : closeModal,
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),

              // Modal card
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: modalHorizontalPadding,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: modalWidth,
                      padding: EdgeInsets.symmetric(
                        horizontal: modalPaddingH,
                        vertical: modalPaddingV,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(modalRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: isMobile ? 20.r : 20.0,
                            offset: Offset(0, isMobile ? 8.r : 8.0),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Modal title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isEditMode)
                                AppText(
                                  text: isEditMode ? "Edit Menu" : "",
                                  size: isMobile ? 16.sp : 16.0,
                                  fontWeight: FontWeight.w600,
                                  color: appTextColor2,
                                ),
                              // GestureDetector(
                              //   onTap: isUploading ? null : closeModal,
                              //   child: Icon(
                              //     Icons.close,
                              //     color: Colors.grey[500],
                              //     size: 22.w,
                              //   ),
                              // ),
                            ],
                          ),

                          SizedBox(height: modalGapMedium),

                          // Current file badge (edit mode)
                          if (isEditMode && editingMenu != null) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12.w : 12.0,
                                vertical: isMobile ? 10.h : 10.0,
                              ),
                              decoration: BoxDecoration(
                                // light orange tint matching your theme
                                color: appButtonColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(
                                  isMobile ? 10.r : 10.0,
                                ),
                                border: Border.all(
                                  color: appButtonColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    color: appButtonColor,
                                    size: isMobile ? 18.w : 18.0,
                                  ),
                                  SizedBox(width: isMobile ? 8.w : 8.0),
                                  Expanded(
                                    child: Text(
                                      "Current: ${editingMenu!.menuName}",
                                      style: TextStyle(
                                        fontSize: isMobile ? 13.sp : 13.0,
                                        fontWeight: FontWeight.w500,
                                        color: appButtonColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isMobile ? 14.h : 14.0),
                          ],

                          // PDF picker box
                          GestureDetector(
                            onTap: isUploading ? null : pickPdfFile,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: pickerPaddingH,
                                vertical: pickerPaddingV,
                              ),
                              decoration: BoxDecoration(
                                // your menuUploadBoxColor from constants
                                color: menuUploadBoxColor,
                                borderRadius: BorderRadius.circular(
                                  pickerRadius,
                                ),
                                border: Border.all(
                                  color: selectedPdfFile != null
                                      ? const Color(0xFF73B256)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  selectedPdfFile != null
                                      ? Icon(
                                          Icons.picture_as_pdf,
                                          color: const Color(0xFF73B256),
                                          size: uploadIconSize,
                                        )
                                      : Image.asset(
                                          uploadIcon,
                                          width: uploadIconSize,
                                          height: uploadIconSize,
                                          fit: BoxFit.contain,
                                        ),
                                  SizedBox(height: modalGapSmall),
                                  if (selectedPdfFile != null)
                                    AppText(
                                      text: selectedPdfFile!.path
                                          .split('/')
                                          .last,
                                      size: 11,
                                      fontWeight: FontWeight.w400,
                                      color: appTextColor2.withValues(
                                        alpha: 0.6,
                                      ),
                                      isCentered: true,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    )
                                  else
                                    const _UploadPdfPrompt(),
                                  if (isEditMode && selectedPdfFile == null)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: isMobile ? 4.h : 4.0,
                                      ),
                                      child: AppText(
                                        text: "Leave empty to keep current PDF",
                                        size: 10,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: modalGapMedium),

                          // Menu name field
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: AppTextFeild(
                                  text: "Menu Name",
                                  size: 15,
                                  controller: fileNameController,
                                  textColor: const Color(0xFF545450),
                                  isRequired: true,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: modalGapLarge),

                          // Action buttons
                          if (isUploading)
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    color: appButtonColor,
                                  ),
                                  SizedBox(height: modalGapSmall),
                                  Text(
                                    _uploadStatus.isEmpty
                                        ? 'Uploading PDF...'
                                        : _uploadStatus,
                                  ),
                                ],
                              ),
                            )
                          else
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  if (isEditMode) {
                                    if (fileNameController.text
                                        .trim()
                                        .isNotEmpty) {
                                      updateMenu();
                                    } else {
                                      _showSnackBar('Please enter a menu name');
                                    }
                                  } else {
                                    if (selectedPdfFile != null &&
                                        fileNameController.text
                                            .trim()
                                            .isNotEmpty) {
                                      uploadMenu();
                                    } else {
                                      _showSnackBar(
                                        'Please select a file and enter a menu name',
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  width: actionButtonWidth,
                                  height: actionButtonHeight,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF73B256),
                                    borderRadius: BorderRadius.circular(
                                      isMobile ? 10.r : 10.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    isEditMode ? "Update" : "Upload",
                                    style: TextStyle(
                                      fontSize: actionTextSize,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pdfBox(MenuModel menu) {
    final size = MediaQuery.sizeOf(context);
    final isWideShortPhone = _isWideShortPhone(context);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final rowHeight = isMobile ? 70.h : 70.0;
    final rowPadding = isMobile ? 16.w : 16.0;
    final rowMargin = isMobile ? 10.h : 10.0;
    final rowRadius = isMobile ? 20.r : 20.0;
    final iconSize = isMobile ? 40.w : 40.0;
    final actionIconSize = isMobile ? 22.w : 22.0;
    final actionGap = isMobile ? 10.w : 10.0;
    final titlePadding = isMobile ? 50.w : 56.0;
    final titleSize = isMobile ? 12.sp : 12.0;

    return GestureDetector(
      onTap: () => downloadPdfFile(menu.pdfPath, menu.menuName, context),
      child: Container(
        width: double.infinity,
        height: rowHeight,
        padding: EdgeInsets.symmetric(horizontal: rowPadding),
        margin: EdgeInsets.only(bottom: rowMargin),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(rowRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: isMobile ? 10.r : 10.0,
              offset: Offset(0, isMobile ? 4.r : 4.0),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              child: Image.asset(
                'assets/images/pdfLogo.png',
                height: iconSize,
                width: iconSize,
                fit: BoxFit.contain,
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: titlePadding),
                child: Text(
                  menu.menuName,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w500,
                    color: appTextColor2,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => pdfEdit(menu),
                    child: Icon(
                      Icons.edit,
                      color: Colors.blue[600],
                      size: actionIconSize,
                    ),
                  ),
                  SizedBox(width: actionGap),
                  GestureDetector(
                    onTap: () => showDeleteConfirmation(menu),
                    child: Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: actionIconSize,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showDeleteConfirmation(MenuModel menu) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.sizeOf(context);
        final isWideShortPhone = _isWideShortPhone(context);
        final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 15.r : 15.0),
          ),
          title: const Text('Delete Menu'),
          content: Text('Are you sure you want to delete "${menu.menuName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteMenu(menu);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteMenu(MenuModel menu) async {
    try {
      setState(() => isLoading = true);
      MenuDeleteModel pdfMenu = MenuDeleteModel(id: menu.uuid);
      MenuDeleteResponseModel response = await menuUploadService.deletePdf(
        pdfMenu,
      );
      setState(() => isLoading = false);
      if (!mounted) return;
      _showSnackBar(
        response.status ? 'Menu "${menu.menuName}" deleted' : response.message,
      );
      getAllPdfs();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Delete failed: ${e.toString()}');
    }
  }

  Future<void> downloadPdfFile(
    String url,
    String fileName,
    BuildContext context,
  ) async {
    try {
      final granted = await requestStoragePermission();
      if (!granted) {
        _showSnackBar('Storage permission denied');
        return;
      }
      Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir =
              await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      final filePath = '${dir.path}/$fileName.pdf';
      await Dio().download(url, filePath);
      if (!mounted) return;
      _showSnackBar('Downloaded $fileName');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Download failed: ${e.toString()}');
    }
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) return true;
      final manageStatus = await Permission.manageExternalStorage.request();
      final storageStatus = await Permission.storage.request();
      return manageStatus.isGranted || storageStatus.isGranted;
    }
    return true;
  }
}
