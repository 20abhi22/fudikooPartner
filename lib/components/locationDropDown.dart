// import 'package:flutter/material.dart';
// import 'package:flutter_typeahead/flutter_typeahead.dart';

// class LocationDropdown extends StatefulWidget {
//   final void Function(String)? onLocationSelected;
//   final IconData? icon;
//   final double? fontSize;
//   final Color? iconColor;
//   final List<String>? locations;
//   final String? hintText;
//   final void Function(String)? onChange;
//   final String? type;
//   final bool? isLoading;

//   const LocationDropdown({
//     Key? key,
//     this.onLocationSelected,
//     this.icon,
//     this.fontSize,
//     this.iconColor,
//     this.locations,
//     this.hintText,
//     this.onChange,
//     this.type,
//     this.isLoading
//   }) : super(key: key);

//   @override
//   State<LocationDropdown> createState() => _LocationDropdownState();
// }

// class _LocationDropdownState extends State<LocationDropdown> {
//   final TextEditingController _controller = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     final locations = widget.locations ?? [] ;

//     return Container(
//       // padding: const EdgeInsets.symmetric(horizontal: 20),
//       height: 60,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.2),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: TypeAheadField<String>(
//               controller: _controller,
//               suggestionsCallback: (pattern) async {
//                   if (widget.isLoading == true) {
//                   return [];
//                 }
//                 return locations
//                     .where((loc) =>
//                     loc.toLowerCase().contains(pattern.toLowerCase()))
//                     .toList();
//               },
//               itemBuilder: (context, suggestion) {
//                 if (widget.isLoading == true) {
//                   return Center(
//                     child: Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: CircularProgressIndicator(),
//                     ),
//                   );
//                 }

//                 return widget.type != null
//                     ? ListTile(
//                         leading: const Icon(Icons.location_on_outlined),
//                         title: Text(suggestion),
//                       )
//                     : ListTile(title: Text(suggestion));
//               },
//               emptyBuilder: (context) {
//                 if (widget.isLoading == true) {
//                   return Center(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: CircularProgressIndicator(),
//                     ),
//                   );
//                 }
//                 return Center(
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Text('No locations found'),
//                   ),
//                 );
//               },

//               onSelected: (value) {
//                 _controller.text = value;
//                 widget.onLocationSelected?.call(value);
//               },
//               builder: (context, controller, focusNode) {
//                 return TextField(
//                   onChanged: (value){
//                     widget.onChange?.call(value);
//                   },
//                   controller: controller,
//                   focusNode: focusNode,
//                   cursorColor: Colors.black,
//                   style: TextStyle(
//                     fontSize: widget.fontSize ?? 16,
//                     fontWeight: FontWeight.w400,
//                     color: Colors.black,
//                   ),
//                   decoration: InputDecoration(

//                     hintText: widget.hintText ?? 'Location',
//                     hintStyle: TextStyle(
//                       fontSize: widget.fontSize ?? 16,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.grey,
//                     ),
//                     border: InputBorder.none,
//                     isCollapsed: true,
//                     contentPadding:
//                     const EdgeInsets.symmetric(vertical: 16,horizontal: 40),
//                   ),
//                 );
//               },
//               decorationBuilder: (context, child) => Material(
//                 color: Colors.white,
//                 elevation: 4,
//                 borderRadius: BorderRadius.circular(12),
//                 child: ConstrainedBox(
//                   constraints:  BoxConstraints(minWidth: MediaQuery.of(context).size.width),
//                   child: child,
//                 ),
//               ),
//               debounceDuration: const Duration(milliseconds: 300),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class LocationDropdown extends StatefulWidget {
  final void Function(String)? onLocationSelected;
  final IconData? icon;
  final double? fontSize;
  final Color? iconColor;
  final List<String>? locations;
  final String? hintText;
  final void Function(String)? onChange;
  final String? type;
  final bool? isLoading;
  final String? externalValue; // ✅ set from outside (e.g. current location)

  const LocationDropdown({
    Key? key,
    this.onLocationSelected,
    this.icon,
    this.fontSize,
    this.iconColor,
    this.locations,
    this.hintText,
    this.onChange,
    this.type,
    this.isLoading,
    this.externalValue,
  }) : super(key: key);

  @override
  State<LocationDropdown> createState() => _LocationDropdownState();
}

class _LocationDropdownState extends State<LocationDropdown> {
  final TextEditingController _controller = TextEditingController();

  @override
  void didUpdateWidget(covariant LocationDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ When parent sets externalValue, update the text field
    if (widget.externalValue != null &&
        widget.externalValue != oldWidget.externalValue &&
        widget.externalValue != _controller.text) {
      _controller.text = widget.externalValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = widget.locations ?? [];

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.icon != null)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(widget.icon, color: widget.iconColor, size: 20),
            ),
          Expanded(
            child: TypeAheadField<String>(
              controller: _controller,
              debounceDuration: Duration.zero,
              suggestionsCallback: (pattern) async {
                if (widget.isLoading == true) return [];
                return locations; // parent's onChange already fetched the right results
              },
              itemBuilder: (context, suggestion) {
                if (widget.isLoading == true) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return widget.type != null
                    ? ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(suggestion),
                      )
                    : ListTile(title: Text(suggestion));
              },
              emptyBuilder: (context) {
                if (widget.isLoading == true) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No locations found'),
                  ),
                );
              },
              onSelected: (value) {
                _controller.text = value;
                widget.onLocationSelected?.call(value);
              },
              builder: (context, controller, focusNode) {
                return TextField(
                  onChanged: (value) {
                    widget.onChange?.call(value);
                  },
                  controller: controller,
                  focusNode: focusNode,
                  cursorColor: Colors.black,
                  style: TextStyle(
                    fontSize: widget.fontSize ?? 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Location',
                    hintStyle: TextStyle(
                      fontSize: widget.fontSize ?? 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: widget.icon != null ? 12 : 20,
                    ),
                  ),
                );
              },
              decorationBuilder: (context, child) => Material(
                color: Colors.white,
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
