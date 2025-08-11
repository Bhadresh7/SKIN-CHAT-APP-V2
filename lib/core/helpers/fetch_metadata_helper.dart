import 'package:flutter/cupertino.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:skin_app_migration/core/helpers/app_logger.dart';

class FetchMetadataHelper {
  static void fetchLinkMetadata(String url) async {
    try {
      final metadata = await MetadataFetch.extract(url);

      AppLoggerHelper.logResponse(metadata?.title);
      AppLoggerHelper.logResponse(metadata?.description);
      AppLoggerHelper.logResponse(metadata?.url);
      AppLoggerHelper.logResponse(metadata?.image);
    } catch (e) {
      debugPrint("Metadata fetch error: $e");
    }
  }
}
