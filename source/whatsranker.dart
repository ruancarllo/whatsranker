import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';

void main() async {
  int currentYear = DateTime.now().year;

  Map<String, num> chatsRanking = {};

  List<FileSystemEntity> directoryEntities = Directory('.').listSync(recursive: true);

  for (FileSystemEntity directoryEntity in directoryEntities) {
    List<String> entityRoutes = directoryEntity.path.split(Platform.pathSeparator);

    String entityName = entityRoutes.last;
    String entityParent = entityRoutes.sublist(0, entityRoutes.length - 1).join(Platform.pathSeparator) + Platform.pathSeparator;

    if (entityName.startsWith('WhatsApp Chat') && entityName.endsWith('.zip')) {
      String chatName;

      chatName = directoryEntity.path.replaceFirst(entityParent, '');
      chatName = chatName.replaceFirst('WhatsApp Chat - ', '');
      chatName = chatName.replaceFirst('.zip', '');

      String chatContent = await getZipChat(directoryEntity.path);

      Iterable<Match> allMessagesMatches = RegExp('\\[\\d{2}\\/\\d{2}\\/$currentYear,? (\\d{1}|\\d{2}):\\d{2}:\\d{2}( (A|P)M])?').allMatches(chatContent);

      chatsRanking[chatName] = allMessagesMatches.length;
    }
  }

  List<MapEntry<String, num>> sortedRanking = chatsRanking.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  for (int i = 0; i < 10 && i < sortedRanking.length; i++) {
    int rankingPosition = i + 1;
    String chatName = sortedRanking[i].key;
    num messagesCount = sortedRanking[i].value;

    print('$rankingPosition. $chatName - $messagesCount');
  }
}


Future<String> getZipChat(String zipPath) async {
  List<int> zipBytes = await File(zipPath).readAsBytes();
  Archive zipArchive = ZipDecoder().decodeBytes(zipBytes);

  for (ArchiveFile zipFile in zipArchive) {
    if (zipFile.name == '_chat.txt') {
      return utf8.decode(zipFile.content);
    }
  }

  throw Exception('A zip file did not return chat content!');
}