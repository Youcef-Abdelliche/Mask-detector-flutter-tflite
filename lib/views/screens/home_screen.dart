import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const HomeScreen({Key key, @required this.cameras}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraImage cameraImage;
  CameraController cameraController;
  String result = "With mask";

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Mask Detector"),
        ),
        body: Center(
            child: Column(children: [
          Container(
            margin: EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width,
            child: !cameraController.value.isInitialized
                ? Container()
                : AspectRatio(
                    aspectRatio: cameraController.value.aspectRatio,
                    child: CameraPreview(cameraController),
                  ),
          ),
          TextContainer(
              result: result,
              color: (result == "With mask") ? Colors.green : Colors.red)
        ])),
      ),
    );
  }

  initCamera() {
    cameraController =
        CameraController(widget.cameras[1], ResolutionPreset.medium);
    cameraController.initialize().then((value) {
      if (!mounted) return;
      setState(() {
        cameraController.startImageStream((imageStream) {
          cameraImage = imageStream;
          runModel();
        });
      });
    });
  }

  loadModel() async {
    await Tflite.loadModel(
        model: "assets/files/model_unquant.tflite",
        labels: "assets/files/labels.txt");
  }

  Future<void> runModel() async {
    if (cameraImage != null) {
      var recognitions = await Tflite.runModelOnFrame(
          bytesList: cameraImage.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          imageHeight: cameraImage.height,
          imageWidth: cameraImage.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 2,
          threshold: 0.1,
          asynch: true);
      recognitions.forEach((element) {
        setState(() {
          result = element["label"];
          print("Label is :" + result);
        });
      });
    }
  }
}

class TextContainer extends StatelessWidget {
  final Color color;
  final String result;
  const TextContainer({
    Key key,
    @required this.color,
    @required this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        result,
        style: TextStyle(
            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24),
      ),
    );
  }
}
