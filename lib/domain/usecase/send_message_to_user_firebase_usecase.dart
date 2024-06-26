import 'package:chat_translator/core/error/failure.dart';
import 'package:chat_translator/domain/entities/entities.dart';
import 'package:chat_translator/domain/repository/repository.dart';
import 'package:dartz/dartz.dart';

class SendMessagetoUserFirebaseUsecase {
  final Repository _repository;

  SendMessagetoUserFirebaseUsecase(this._repository);

  Future<Either<Failure, void>> execute(Message message) async {
    return await _repository.sentMessageToUserFirebase(message);
  }
}
