import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/models/menuupload/menu-delete-model.dart';
import 'package:fudiko/models/menuupload/menu-list-model.dart';
import 'package:fudiko/models/menuupload/menu-update-model.dart';
import 'package:fudiko/models/menuupload/menu-upload-model.dart';
import 'package:fudiko/services/menu-upload-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/translator_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 14.sp,
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
  bool isOpen = false;
  bool isLoading = false;
  bool isEditMode = false;
  bool isUploading = false;
  File? selectedPdfFile;
  List<MenuModel> menus = [];
  MenuModel? editingMenu;
  final TextEditingController fileNameController = TextEditingController();
  MenuUploadService menuUploadService = MenuUploadService();

  Future<void> uploadMenu() async {
    if (selectedPdfFile == null || fileNameController.text.isEmpty) {
      _showSnackBar('Please select a file and enter a menu name');
      return;
    }
    setState(() => isUploading = true);
    try {
      MenuUploadModel menu = MenuUploadModel(
        file: selectedPdfFile!,
        menuName: fileNameController.text.trim(),
      );
      MenuUploadResponseModel response = await menuUploadService.addMenu(menu);
      if (!mounted) return;
      _showSnackBar(response.message);
      if (response.status) getAllPdfs();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Upload failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  Future<void> updateMenu() async {
    if (editingMenu == null || fileNameController.text.isEmpty) {
      _showSnackBar('Invalid menu data');
      return;
    }
    setState(() => isUploading = true);
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
      if (response.status) getAllPdfs();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Update failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isUploading = false);
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
        setState(() {
          selectedPdfFile = File(result.files.single.path!);
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
                      height: 150.h,
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
                        // child: Icon(
                        //   Icons.arrow_back_ios_outlined,
                        //   size: 30.w,
                        //   color: Colors.white,
                        // ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                if (isLoading)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: appButtonColor),
                    ),
                  )
                else if (menus.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: menus.length,
                      itemBuilder: (context, index) => _pdfBox(menus[index]),
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
                            size: 60.w,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            "No PDF Available",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14.sp,
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
              bottom: 40.h,
              right: 20.w,
              child: GestureDetector(
                onTap: isUploading ? null : openAddModal,
                child: Container(
                  width: 75.w,
                  height: 75.w,
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
                      width: 10.w,
                      height: 10.h,
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
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 24.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20.r,
                            offset: Offset(0, 8.r),
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
                                  size: 16.sp,
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
        
                          SizedBox(height: 18.h),
        
                          // Current file badge (edit mode)
                          if (isEditMode && editingMenu != null) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                // light orange tint matching your theme
                                color: appButtonColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10.r),
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
                                    size: 18.w,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      "Current: ${editingMenu!.menuName}",
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w500,
                                        color: appButtonColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 14.h),
                          ],
        
                          // PDF picker box
                          GestureDetector(
                            onTap: isUploading ? null : pickPdfFile,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 22.h,
                              ),
                              decoration: BoxDecoration(
                                // your menuUploadBoxColor from constants
                                color: menuUploadBoxColor,
                                borderRadius: BorderRadius.circular(15.r),
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
                                          size: 32.w,
                                        )
                                      : Image.asset(
                                          uploadIcon,
                                          width: 32.w,
                                          height: 32.h,
                                          fit: BoxFit.contain,
                                        ),
                                  SizedBox(height: 8.h),
                                  if (selectedPdfFile != null)
                                    AppText(
                                      text: selectedPdfFile!.path.split('/').last,
                                      size: 11,
                                      fontWeight: FontWeight.w400,
                                      color: appTextColor2.withValues(alpha: 0.6),
                                      isCentered: true,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    )
                                  else
                                    const _UploadPdfPrompt(),
                                  if (isEditMode && selectedPdfFile == null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4.h),
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
        
                          SizedBox(height: 18.h),
        
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
        
                          SizedBox(height: 22.h),
        
                          // Action buttons
                          if (isUploading)
                            Center(
                              child: CircularProgressIndicator(
                                color: appButtonColor,
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
                                      closeModal();
                                    } else {
                                      _showSnackBar('Please enter a menu name');
                                    }
                                  } else {
                                    if (selectedPdfFile != null &&
                                        fileNameController.text
                                            .trim()
                                            .isNotEmpty) {
                                      uploadMenu();
                                      closeModal();
                                    } else {
                                      _showSnackBar(
                                        'Please select a file and enter a menu name',
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  width: 130.w,
                                  height: 40.h,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF73B256),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    isEditMode ? "Update" : "Upload",
                                    style: TextStyle(
                                      fontSize: 13.sp,
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
    return GestureDetector(
      onTap: () => downloadPdfFile(menu.pdfPath, menu.menuName, context),
      child: Container(
        width: double.infinity,
        height: 70.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10.r,
              offset: Offset(0, 4.r),
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
                height: 40.h,
                width: 40.w,
                fit: BoxFit.contain,
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 50.w),
                child: Text(
                  menu.menuName,
                  style: TextStyle(
                    fontSize: 12.sp,
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
                      size: 22.w,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: () => showDeleteConfirmation(menu),
                    child: Icon(Icons.delete, color: Colors.red, size: 22.w),
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
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
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
