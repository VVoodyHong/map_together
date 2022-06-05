import 'dart:io';

import 'package:flutter/material.dart';
import 'package:map_together/utils/constants.dart';

class ImageUploader extends StatelessWidget {

  final double? height;
  final double? width;
  final List<File> images;
  final VoidCallback onCreate;
  final Function(int index) onDelete;

  ImageUploader({
    this.height,
    this.width,
    required this.images,
    required this.onCreate,
    required this.onDelete
  });

  @override
  Widget build(BuildContext context) {
    
    return Column(
      children: [
        Container(
          height: height ?? 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: MtColor.paleGrey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (overscroll) {
              overscroll.disallowIndicator();
              return true;
            },
            child: images.isNotEmpty ? ListView.builder(
              itemCount: images.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (BuildContext context, int index) {
                return Row(
                  children: [
                    SizedBox(
                      height: height ?? 150,
                      width: width ?? 150,
                      child: Stack(
                        children: [
                          Container(
                            margin: EdgeInsets.all(15),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: FileImage(images[index])
                              )
                            ),
                          ),
                          GestureDetector(
                            onTap: () {onDelete(index);},
                            child: Container(
                              margin: EdgeInsets.only(left: (width ?? 150) - 30, top: 5),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: MtColor.paleBlack,
                                  borderRadius: BorderRadius.circular(20)
                                ),
                                height: 25,
                                width: 25,
                                alignment: Alignment.topRight,
                                child: Center(
                                  child: Icon(
                                    Icons.close,
                                    color: MtColor.white,
                                    size: 20,
                                  ),
                                ),
                              )
                            ),
                          ),
                        ],
                      ),
                    ),
                    (images.length < 10 && index == images.length - 1) ? GestureDetector(
                      onTap: onCreate,
                      child: SizedBox(
                        height: height ?? 150,
                        width: width ?? 150,
                        child: Stack(
                          children: [
                            Container(
                              margin: EdgeInsets.all(15),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: MtColor.grey.withOpacity(0.3),
                                  width: 1
                                )
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.add_a_photo,
                                  color: MtColor.grey,
                                  size: 30,
                                ),
                              )
                            ),
                          ],
                        ),
                      ),
                    ) : Container()
                  ],
                );
              }
            ) : GestureDetector(
              onTap: onCreate,
              child: SizedBox(
                height: height ?? 150,
                width: width ?? 150,
                child: Stack(
                  children: [
                    Container(
                      margin: EdgeInsets.all(15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add_a_photo,
                          color: MtColor.grey,
                          size: 30,
                        ),
                      )
                    ),
                  ],
                ),
              ),
            )
          )
        ),
        Container(
          alignment: Alignment.centerRight,
          margin: EdgeInsets.only(top: 5),
          child: Text(
            '(${(images.length)}/10)',
            style: TextStyle(
              fontSize: 16
            )
          ),
        )
      ],
    );
  }
  
}