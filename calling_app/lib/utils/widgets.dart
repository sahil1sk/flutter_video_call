import 'package:flutter/material.dart';

Widget customButtons({
  required Function function,
  required Icon icon,
  required Color color,
  required double padding,
}) {
  return RawMaterialButton(
    onPressed: () => function(),
    child: icon,
    shape: const CircleBorder(),
    elevation: 2.0,
    fillColor: color,
    padding: EdgeInsets.all(padding),
  );
}


Widget customSearchField({required TextEditingController controller, required Size size, required Function onChange}) {
  return Container(
    margin:
    const EdgeInsets.all(10),
    height: 50,
    width: size.width,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10)),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 5,
          blurRadius: 7,// changes position of shadow
        ),
      ],
    ),
    child: TextField(
      controller: controller,
      onChanged: (e) => onChange(e),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        hintText: "Search here...",
      ),
    ),
  );
}