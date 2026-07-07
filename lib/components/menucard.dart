import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/components/appswitch.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-delete-model.dart';
import 'package:fudiko/screens/others/individuvalMenuUploadEdit.dart';
import 'package:fudiko/services/individual-menu-upload-service.dart';

class MenuCard extends StatefulWidget {
  final String id;
  final String url;
  final String itemName;
  final String itemPrice;
  final String itemDescription;
  final String status;
  final String itemCategory;
  final Function refreshFun;

  const MenuCard({
    super.key,
    required this.id,
    required this.url,
    required this.itemName,
    required this.itemPrice,
    required this.itemDescription,
    required this.status,
    required this.itemCategory,
    required this.refreshFun,
  });

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  bool isLoading = false;
  IndividualMenuUploadService individualMenuUploadService =
      IndividualMenuUploadService();

  bool _isWideShortPhone(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Breakpoints.isMobile(size.width) &&
        size.width >= 500 &&
        size.height <= 760;
  }

  bool _isMobile(BuildContext context) {
    return Breakpoints.isMobile(MediaQuery.sizeOf(context).width) &&
        !_isWideShortPhone(context);
  }

  double _imageWidth(BuildContext context) {
    return _isMobile(context) ? 120.w : 120.0;
  }

  double _imageHeight(BuildContext context) {
    return _isMobile(context) ? 100.h : 100.0;
  }

  String? _resolvedImageUrl() {
    final imageUrl = widget.url.trim();
    if (imageUrl.isEmpty) return null;

    final uri = Uri.tryParse(imageUrl);
    if (uri != null && uri.hasScheme) return imageUrl;
    if (imageUrl.startsWith('//')) return 'https:$imageUrl';

    final baseUri = Uri.parse(DioClient.dio.options.baseUrl);
    final origin = '${baseUri.scheme}://${baseUri.host}';
    final normalizedPath = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
    return '$origin$normalizedPath';
  }

  Widget _buildImagePlaceholder({bool isError = false}) {
    final isMobile = _isMobile(context);
    final iconSize = isMobile ? 28.w : 28.0;

    return Container(
      height: _imageHeight(context),
      width: _imageWidth(context),
      color: Colors.grey.shade200,
      child: Icon(
        isError ? Icons.broken_image_outlined : Icons.image_outlined,
        color: Colors.grey.shade600,
        size: iconSize,
      ),
    );
  }

  Widget _buildMenuImage() {
    final isMobile = _isMobile(context);
    final spinnerSize = isMobile ? 22.w : 22.0;
    final strokeWidth = isMobile ? 2.w : 2.0;
    final imageUrl = _resolvedImageUrl();
    if (imageUrl == null) {
      return _buildImagePlaceholder();
    }

    return Image.network(
      imageUrl,
      height: _imageHeight(context),
      width: _imageWidth(context),
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: _imageHeight(context),
          width: _imageWidth(context),
          color: Colors.grey.shade200,
          child: Center(
            child: SizedBox(
              height: spinnerSize,
              width: spinnerSize,
              child: CircularProgressIndicator(
                strokeWidth: strokeWidth,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          _buildImagePlaceholder(isError: true),
    );
  }

  Future<void> deleteMenu() async {
    setState(() {
      isLoading = true;
    });
    IndividualMenuDeleteModel menu = IndividualMenuDeleteModel(
      menuId: widget.id,
    );
    IndividualMenuDeleteResponseModel response =
        await individualMenuUploadService.deleteMenu(menu);
    setState(() {
      isLoading = false;
    });
    if (response.status) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    }
    widget.refreshFun();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final cardRadius = isMobile ? 20.r : 20.0;
    final bottomMargin = isMobile ? 20.h : 20.0;
    final shadowBlur = isMobile ? 10.r : 10.0;
    final imageGap = isMobile ? 14.w : 14.0;
    final contentPadding = isMobile ? 14.w : 14.0;
    final titleSize = isMobile ? 14.sp : 14.0;
    final priceSize = isMobile ? 12.sp : 12.0;
    final descriptionSize = isMobile ? 11.sp : 11.0;
    final titleGap = isMobile ? 4.h : 4.0;
    final priceGap = isMobile ? 6.h : 6.0;
    final buttonTopGap = isMobile ? 12.h : 12.0;
    final buttonHeight = isMobile ? 30.h : 30.0;
    final buttonGap = isMobile ? 10.w : 10.0;

    return Container(
      margin: EdgeInsets.only(bottom: bottomMargin),
      // padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: shadowBlur,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(cardRadius),
                bottomLeft: Radius.circular(cardRadius),
              ),
              child: _buildMenuImage(),
            ),
            SizedBox(width: imageGap),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppText(
                            text: widget.itemName.toUpperCase(),
                            size: titleSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        AppSwitch(
                          initialValue: widget.status == "Active",
                          onToggle: (val) {},
                        ),
                      ],
                    ),
                    SizedBox(height: titleGap),

                    AppText(
                      text: "\u20B9 ${widget.itemPrice}",
                      size: priceSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),

                    SizedBox(height: priceGap),

                    AppText(
                      text: widget.itemDescription,
                      size: descriptionSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[800]!,
                      lineSpacing: 1.3,
                    ),

                    SizedBox(height: buttonTopGap),

                    // Edit & Delete Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: buttonHeight,
                            child: AppButton(
                              text: "Edit",
                              size: 10,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        IndividualMenuUploadEdit(
                                          menuId: widget.id,
                                          itemPrice: widget.itemPrice,
                                          itemDescription:
                                              widget.itemDescription,
                                          itemName: widget.itemName,
                                          itemCategory: widget.itemCategory,
                                          itemImage: widget.url,
                                        ),
                                  ),
                                ).then((_) {
                                  widget.refreshFun();
                                });
                              },
                              bgColor1: Colors.blue,
                              bgColor2: Colors.blue,
                              borderRadius: 5,
                            ),
                          ),
                        ),
                        SizedBox(width: buttonGap),
                        Expanded(
                          child: SizedBox(
                            height: buttonHeight,
                            child: AppButton(
                              text: isLoading ? "Deleting..." : "Delete",
                              size: 10,
                              onPressed: () {
                                deleteMenu();
                              },
                              bgColor1: Colors.red,
                              bgColor2: Colors.red,
                              borderRadius: 5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
