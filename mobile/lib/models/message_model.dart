import 'dart:io';

class MessageModel {
  final bool isUser;
  final String? text;
  final File? image;
  final String? networkImage;
  final String? type;
  final dynamic data;
  final bool isLoading;

  MessageModel({
    required this.isUser,
    this.text,
    this.image,
    this.networkImage,
    this.type,
    this.data,
    this.isLoading = false,
  });
 
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      isUser: json['isUser'],
      text: json['text'],
      networkImage: json['networkImage'],
      type: json['type'],
      data: json['data'],
      isLoading: json['isLoading'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isUser': isUser,
      'text': text,
      'networkImage': networkImage,
      'type': type,
      'data': data,
      'isLoading': isLoading,
    };
  }
}
