import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html_to_pdf_plus/flutter_html_to_pdf_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';
import 'bottombar_ios.dart/bottombar_ios.dart';
import 'constants.dart';
import 'package:path_provider/path_provider.dart';

import 'drawer.dart';
import 'utils/downloads_path_provider.dart';

const kHtml = """
<h1>Heading</h1>
<p>A paragraph with <strong>strong</strong> <em>emphasized</em> text.</p>
<ol>
  <li>List item number one</li>
  <li>
    Two
    <ul>
      <li>2.1 (nested)</li>
      <li>2.2</li>
    </ul>
  </li>
  <li>Three</li>
</ol>
<p>And YouTube video!</p>
<iframe src="https://www.youtube.com/embed/jNQXAC9IVRw" width="560" height="315"></iframe>
""";

class SalarySlip extends StatefulWidget {
  const SalarySlip({super.key});

  @override
  _SalarySlipState createState() => _SalarySlipState();
}

class _SalarySlipState extends State<SalarySlip>
    with SingleTickerProviderStateMixin<SalarySlip> {
  bool visible = false;
  String? generatedPdfFilePath;
  //final pdf = Document();
  var currDt = DateTime.now();
  Map? data;
  Map? datanew;
  var userData;
  var userDatanew;
  var cdetails;
  var accdetails;
  List? earnings;
  var concatenate;
  List<dynamic>? newListlabel;
  List<dynamic>? newListamount;
  List<dynamic>? deductionlabel;
  List<dynamic>? deductionamount;
  List? deductions;
  var workeddays;
  var leave;
  var paiddays;
  var notpayable;
  var tovrt;
  String? _mylist;
  String? _mycredit;
  String? username;
  String? htmldata;
  String? email;
  String? ppic;
  String? ppic2;
  String? uid;
  String? cid;
  var Name;
  var fathername;
  var sundayandholiday;
  var aadhar;
  var desig;
  var eid;
  List<dynamic>? list;
  var compname;
  String? compadd;
  var compdist;
  var compstate;
  var comppincode;
  var complogo;
  var tearnings;
  var tdeduct;
  var elist;
  String? val;
  var listlabel;
  var listamount = [];
  var netsalary;
  var reimbursement;
  var loanadj;
  var salaryadv;
  var adjustment;
  var advancesalary;
  var loandeducted;
  var loantaken;
  var loanoutstanding;
  var loanpaid;
  var bname;
  var accno;
  var panno;
  var esino;
  var pfno;
  var year;
  var month;
  String? screen;
  var newdata;
  var i;
  var y;
  var myearninglist;
  var myearningamount;
  var htmlContent;
  Future<Directory?> downloadsDirectory =
      DownloadsPathProvider.downloadsDirectory;

  Future<Directory?> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      return await DownloadsPathProvider.downloadsDirectory;
    }
    return await getApplicationDocumentsDirectory();
  }

  _requestPermissions() async {
    Map<Permission, PermissionStatus> permission = await [
      Permission.storage,
    ].request();

    if (permission[Permission.storage] != PermissionStatus.granted) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();
    }
  }

  Future<void> generateDocument() async {
    htmlContent = """ $htmldata """;
    final dir = await _getDownloadDirectory();
    await _requestPermissions();
    log("message");
    final Directory appDocDirFolder =
        Directory('${dir!.path}/Ezhrm/Salary Slips');
    if (await appDocDirFolder.exists()) {
      //print('exists');
      appDocDir = await _getDownloadDirectory();
      var targetPath = '${appDocDir!.path}/Ezhrm/Salary Slips';
      var targetFileName = "$_valuenew $_value";
      final dir = await getExternalStorageDirectory();
      final String path = "${dir!.path}/example.pdf";
      final file = File(path);
      final generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
        content: htmlContent,
        configuration: PrintPdfConfiguration(
          targetDirectory: targetPath, // same as your old targetPath
          targetName: targetFileName, // same as your old targetFileName
          margins: PdfPageMargin(top: 50, bottom: 50, left: 50, right: 50),
          printOrientation: PrintOrientation.Landscape,
          printSize: PrintSize.A4,
        ),
      );

      generatedPdfFilePath = generatedPdfFile.path;
      Fluttertoast.showToast(
          msg: "Pdf Saved At \n ${appDocDir!.path}/Ezhrm/Salary Slips",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 3000,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 12.0);
      return;
    } else {
      final Directory appDocNewFolder =
          await appDocDirFolder.create(recursive: true);
      appDocDir = await _getDownloadDirectory();
      var targetPath = '${appDocDir!.path}/Ezhrm/Salary Slips';
      var targetFileName = "$_valuenew $_value";
      final dir = await getExternalStorageDirectory();
      final String path = "${dir!.path}/example.pdf";
      final file = File(path);
      final generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
        content: htmlContent,
        configuration: PrintPdfConfiguration(
          targetDirectory: targetPath, // same as your old targetPath
          targetName: targetFileName, // same as your old targetFileName
          margins: PdfPageMargin(top: 50, bottom: 50, left: 50, right: 50),
          printOrientation: PrintOrientation.Landscape,
          printSize: PrintSize.A4,
        ),
      );

      generatedPdfFilePath = generatedPdfFile.path;
      Fluttertoast.showToast(
          msg: "Pdf Saved At \n ${appDocDir!.path}/Ezhrm/Salary Slips",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 3000,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 12.0);
    }
  }

  Directory? appDocDir;
  var internet = 'yes';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    getEmail();
    String monthNumber = (DateTime.now().month - 1).toString();
    _valuenew = monthNumber == "1"
        ? "Jan"
        : monthNumber == "2"
            ? "Feb"
            : monthNumber == "3"
                ? "Mar"
                : monthNumber == "4"
                    ? "Apr"
                    : monthNumber == "5"
                        ? "May"
                        : monthNumber == "6"
                            ? "Jun"
                            : monthNumber == "7"
                                ? "Jul"
                                : monthNumber == "8"
                                    ? "Aug"
                                    : monthNumber == "9"
                                        ? "Sep"
                                        : monthNumber == "10"
                                            ? "Oct"
                                            : monthNumber == "11"
                                                ? "Nov"
                                                : "Dec";
    _value = DateTime.now().year.toString();
    setState(() {
      userData = 'started';
    });
    // fetchCredit();
  }

  Future getEmail() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    SharedPreferences preferencess = await SharedPreferences.getInstance();
    SharedPreferences preferencesimg = await SharedPreferences.getInstance();
    SharedPreferences preferencesimg2 = await SharedPreferences.getInstance();
    SharedPreferences preferencesuid = await SharedPreferences.getInstance();
    SharedPreferences preferencecuid = await SharedPreferences.getInstance();
    setState(() {
      email = preferences.getString('email');
      username = preferencess.getString('username');
      ppic = preferencesimg.getString('profile');
      ppic2 = preferencesimg2.getString('profile2');
      uid = preferencesuid.getString('uid');
      cid = preferencecuid.getString('comp_id');
    });
  }

  Future fetchList() async {
    SharedPreferences preferencecuid = await SharedPreferences.getInstance();
    SharedPreferences preferencesuid = await SharedPreferences.getInstance();
    try {
      var uri = "$customurl/controller/process/app/extras.php";
      var formdata = FormData.fromMap({
        'uid': preferencesuid.getString('uid'),
        'cid': preferencecuid.getString('comp_id'),
        'type': 'salary_slip2',
        'month': _valuenew,
        'year': _value
      });

      var dio = Dio();
      var response = await dio.request(
        uri,
        options: Options(
          method: 'POST',
        ),
        data: formdata,
      );

      log({
        'uid': preferencesuid.getString('uid'),
        'cid': preferencecuid.getString('comp_id'),
        'type': 'salary_slip2',
        'month': _valuenew,
        'year': _value
      }.toString());
      data = json.decode(response.data);
      log(response.statusCode.toString());
      log(data.toString());
      userData = data!["data"];
      htmldata = data!["data"];
      setState(() {});
      if (userData == null) {
        setState(() {
          screen = 'not found';
        });
      }
      loadLocalHTML();
      setState(() {
        visible = true;
      });

      if (htmldata != null && webViewController != null) {
        webViewController!.loadHtmlString(htmldata!);
      }
      if (debug == 'yes') {
        //print("check here");
      }
    } catch (error) {
      //print(error);
      //print("aman error");
    }
  }

  WebViewControllerPlus? webViewController;
  loadLocalHTML() async {
    webViewController = WebViewControllerPlus()
      ..enableZoom(true)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith("https://")) {
              return NavigationDecision.navigate;
            } else {
              return NavigationDecision.prevent;
            }
          },
        ),
      );

    webViewController!.loadHtmlString(
      htmldata!,
    );
  }

  String _value = 'start';
  String _valuenew = 'start';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: const bottombar_ios(),
        drawer:
            const CustomDrawer(currentScreen: AvailableDrawerScreens.salary),
        appBar: AppBar(
          title: const Text(
            'Salary Slip',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.indigo,
                  Colors.blue.shade600,
                ],
              ),
            ),
          ),
          actions: [
            userData == null || userData == 'started'
                ? const SizedBox()
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [Colors.green, Colors.blue],
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          generateDocument();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Generate Pdf',
                              style: TextStyle(
                                  fontFamily: font1, color: Colors.white),
                            ),
                            Icon(
                              Icons.arrow_circle_down,
                              color: Colors.white,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
          ],
        ),
        backgroundColor: Colors.blue,
        body: Container(
            child: userData == 'started'
                ? Container(
                    color: Colors.white,
                    child: const Center(
                        child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'To Generate Salary Slip, Please Select Month And Year',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    )),
                  )
                : userData == null
                    ? Container(
                        color: Colors.white,
                        child: Center(
                            child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: screen == 'not found'
                                    ? const Text(
                                        'No Salary Slip Found',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 20,
                                        ),
                                      )
                                    : const Text(
                                        'Please Wait....',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 20,
                                        ),
                                      ))),
                      )
                    : WebViewWidget(
                        controller: webViewController!,
                      )),
        floatingActionButton: Container(
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 5, 0, 5),
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue, Colors.indigo],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
                    child: DropdownButtonHideUnderline(
                      child: ButtonTheme(
                        child: DropdownButton(
                            dropdownColor: Colors.black,
                            icon: const Padding(
                              padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
                              child: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                            ),
                            hint: const Text(
                              'Select Month',
                              style: TextStyle(
                                  fontFamily: font1, color: Colors.white),
                            ),
                            value: _valuenew,
                            items: const [
                              DropdownMenuItem(
                                value: 'start',
                                child: Text(
                                  'Select Month',
                                  style: TextStyle(
                                      fontFamily: font1, color: Colors.white),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Jan',
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  child: Text(
                                    'January',
                                    style: TextStyle(
                                        fontFamily: font1, color: Colors.white),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Feb',
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  child: Text(
                                    'February',
                                    style: TextStyle(
                                        fontFamily: font1, color: Colors.white),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Mar',
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  child: Text(
                                    'March',
                                    style: TextStyle(
                                        fontFamily: font1, color: Colors.white),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Apr',
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  child: Text(
                                    'April',
                                    style: TextStyle(
                                        fontFamily: font1, color: Colors.white),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'May',
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  child: Text(
                                    'May',
                                    style: TextStyle(
                                        fontFamily: font1, color: Colors.white),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Jun',
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  child: Text(
                                    'June',
                                    style: TextStyle(
                                        fontFamily: font1, color: Colors.white),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Jul',
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  child: Text(
                                    'July',
                                    style: TextStyle(
                                        fontFamily: font1, color: Colors.white),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Aug',
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  child: Text(
                                    'August',
                                    style: TextStyle(
                                        fontFamily: font1, color: Colors.white),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Sep',
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  child: Text(
                                    'September',
                                    style: TextStyle(
                                        fontFamily: font1, color: Colors.white),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Oct',
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  child: Text(
                                    'October',
                                    style: TextStyle(
                                        fontFamily: font1, color: Colors.white),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Nov',
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  child: Text(
                                    'November',
                                    style: TextStyle(
                                        fontFamily: font1, color: Colors.white),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Dec',
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  child: Text(
                                    'December',
                                    style: TextStyle(
                                        fontFamily: font1, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _valuenew = value!;
                                if (debug == 'yes') {
                                  //print(_valuenew);
                                }
                              });
                            }),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue, Colors.indigo],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      child: DropdownButton(
                          icon: const Padding(
                            padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
                            child: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                          ),
                          dropdownColor: Colors.black,
                          hint: const Padding(
                            padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                            child: Text(
                              'Select Year',
                              style: TextStyle(
                                  fontFamily: font1, color: Colors.white),
                            ),
                          ),
                          value: _value,
                          items: [
                            const DropdownMenuItem(
                              value: 'start',
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                child: Text(
                                  'Select Year',
                                  style: TextStyle(
                                      fontFamily: font1, color: Colors.white),
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: (currDt.year - 1).toString(),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                                child: Text(
                                  (currDt.year - 1).toString(),
                                  style: const TextStyle(
                                      fontFamily: font1, color: Colors.white),
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: currDt.year.toString(),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                                child: Text(
                                  currDt.year.toString(),
                                  style: const TextStyle(
                                      fontFamily: font1, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _value = value!;
                              if (debug == 'yes') {
                                //print(_value);
                              }
                            });
                          }),
                    ),
                  ),
                ),
              ),
              _value == 'start' || _valuenew == 'start'
                  ? Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.grey, Colors.grey],
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          //print("aman soni");
                        },
                        child: const Text(
                          'View',
                          style:
                              TextStyle(color: Colors.white, fontFamily: font1),
                        ),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black, Colors.black],
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          //  checkinternetconnection();

                          fetchList();
                          setState(() {
                            userData = null;
                          });
                        },
                        child: const Text(
                          'View',
                          style:
                              TextStyle(color: Colors.white, fontFamily: font1),
                        ),
                      ),
                    ),
            ],
          ),
        )
        // bottomNavigationBar: CustomBottomNavigationBar(),

        );
  }
}
