import 'package:file_picker/file_picker.dart';

sealed class AppAction {
  const AppAction();
}

class PickFilesAction extends AppAction {
  const PickFilesAction();
}

class GenerateAction extends AppAction {
  const GenerateAction({
    required this.files,
    required this.sizes,
    required this.pixelRatios,
  });
  final List<double> pixelRatios;
  final List<int> sizes;
  final List<PlatformFile> files;
}

class ExitAction extends AppAction {
  const ExitAction();
}

class DownloadAction extends AppAction {
  const DownloadAction();
}
