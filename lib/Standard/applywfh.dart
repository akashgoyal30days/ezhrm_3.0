import 'package:ezhrm/Standard/services/shared_preferences_singleton.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_styled_toast/flutter_styled_toast.dart';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'bottombar_ios.dart/bottombar_ios.dart';
import 'constants.dart';

class ApplyWrkfrmhome extends StatefulWidget {
  const ApplyWrkfrmhome({super.key});

  @override
  _ApplyWrkfrmhomeState createState() => _ApplyWrkfrmhomeState();
}

class _ApplyWrkfrmhomeState extends State<ApplyWrkfrmhome>
    with SingleTickerProviderStateMixin<ApplyWrkfrmhome> {
  bool visible = true;
  Map? data;
  Map? datanew;
  List? userData;
  List? userDatanew;
  String? _mylist;
  String? _mycredit;
  String? username;
  String? email;
  String? ppic;
  String? ppic2;
  String? uid;
  String? cid;
  dynamic reasonController = TextEditingController();
  var difference = "";
  var newdata;

  Future<void> loaderFull(BuildContext context) async {
    return await showDialog(
        // barrierDismissible: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return WillPopScope(
              onWillPop: () async => false,
              child: const AlertDialog(
                backgroundColor: Colors.white,
                elevation: 0,
                content: SizedBox(
                    height: 40,
                    child: Center(
                        child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                    ))),
                title: Center(
                    child: Text(
                  'Processing...',
                  style: TextStyle(color: Colors.blue),
                )),
              ),
            );
          });
        });
  }

  loadProgress() {
    if (visible == true) {
      setState(() {
        visible = false;
      });
    } else {
      setState(() {
        visible = true;
      });
    }
  }

  @override
  void initState() {
    getEmail();
    fetchList();
    fetchCredit();

    super.initState();
  }

  Future getEmail() async {
    setState(() {
      email = SharedPreferencesInstance.getString('email');
      username = SharedPreferencesInstance.getString('username');
      ppic = SharedPreferencesInstance.getString('profile');
      ppic2 = SharedPreferencesInstance.getString('profile2');
      uid = SharedPreferencesInstance.getString('uid');
      cid = SharedPreferencesInstance.getString('comp_id');
    });
  }

  Future fetchList() async {
    try {
      var uri = "$customurl/controller/process/app/leave.php";
      final response = await http.post(Uri.parse(uri), body: {
        'uid': SharedPreferencesInstance.getString('uid'),
        'cid': SharedPreferencesInstance.getString('comp_id'),
        'type': 'fetch_quota'
      }, headers: <String, String>{
        'Accept': 'application/json',
      });
      data = json.decode(response.body);
      setState(() {
        visible = true;
        userData = data!["data"];
        visible = true;
      });
      if (debug == 'yes') {
        //debugPrint(userData.toString());
      }
    } catch (error) {}
  }

  Future fetchCredit() async {
    try {
      var urii = "$customurl/controller/process/app/leave.php";
      final responsenew = await http.post(Uri.parse(urii), body: {
        'uid': SharedPreferencesInstance.getString('uid'),
        'cid': SharedPreferencesInstance.getString('comp_id'),
        'type': 'fetch_credit'
      }, headers: <String, String>{
        'Accept': 'application/json',
      });
      datanew = json.decode(responsenew.body);
      setState(() {
        visible = true;
        userDatanew = datanew!["data"];
        if (userDatanew == null) {
          setState(() {
            userDatanew = [];
          });
        }
        visible = true;
      });
      if (debug == 'yes') {
        //debugPrint(userDatanew.toString());
        //debugPrint(datanew.toString());
      }
    } catch (error) {}
  }

  String? resulted;
  DateTime selectedDate = DateTime.now();
  DateTime selectedDatenew = DateTime.now();
  var customFormat = DateFormat('yyyy-MM-dd');
  var customFormatnew = DateFormat('yyyy-MM-dd');
  Future<void> showPicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2050),
    );

    if (picked != selectedDate && picked != selectedDatenew) {
      setState(() {
        selectedDate = picked!;
        selectedDatenew = picked;
      });
    }
  }

  Future wfh() async {
    try {
      var urii = "$customurl/controller/process/app/leave.php";
      final responseneww = await http.post(Uri.parse(urii), body: {
        'uid': SharedPreferencesInstance.getString('uid'),
        'cid': SharedPreferencesInstance.getString('comp_id'),
        'type': 'apply_work_home',
        'date_from': customFormat.format(selectedDate),
        'reason': reasonController.text
      }, headers: <String, String>{
        'Accept': 'application/json',
      });
      newdata = json.decode(responseneww.body);
      if (newdata.containsKey('status')) {
        setState(() {
          visible = false;
        });
        if (newdata['status'] == true) {
          btnval = 'hide';
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ApplyWrkfrmhome()));
          setState(() {
            Fluttertoast.showToast(
                msg: "Your work from home is applied successfully",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 2,
                backgroundColor: Colors.white,
                textColor: Colors.black,
                fontSize: 16.0);
            _mycredit = null;
            _mylist = null;
            reasonController.clear();
          });
        } else if (newdata['status'] == false) {
          setState(() {
            btnval = 'hide';
            Fluttertoast.showToast(
                msg: "Already applied for this date please check and try again",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 2,
                backgroundColor: Colors.white,
                textColor: Colors.black,
                fontSize: 16.0);
            _mycredit = null;
            _mylist = null;
            reasonController.clear();
          });
        }
      }
      if (debug == 'yes') {
        //debugPrint(newdata.toString());
        //print('from- ${customFormat.format(selectedDate)}');
        //print('To- ${customFormatnew.format(selectedDatenew)}');
      }
    } catch (error) {
      btnval = 'hide';
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "Something went wrong, please retry",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.red,
      ));
    }
  }

  String? btnval;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const bottombar_ios(),
      appBar: AppBar(
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
        title: const Text(
          "Apply for WFH",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: userDatanew == null
          ? Center(
              child: LoadingAnimationWidget.flickr(
                leftDotColor: Colors.indigo,
                rightDotColor: Colors.blue,
                size: 60,
              ),
            )
          : SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  const Divider(),
                  Center(
                    child: Column(
                      children: [
                        Card(
                          margin: const EdgeInsets.all(8),
                          child: InkWell(
                            onTap: () => showPicker(context),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Select Date",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff072a99),
                                      )),
                                  TextButton(
                                      onPressed: () => showPicker(context),
                                      style: ButtonStyle(
                                          padding: WidgetStateProperty.all(
                                              EdgeInsets.zero),
                                          textStyle: WidgetStateProperty.all(
                                              const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          foregroundColor:
                                              WidgetStateProperty.all(
                                            const Color(0xff072a99),
                                          )),
                                      child: Text(DateFormat('dd MMM y')
                                          .format(selectedDate))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Reason",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff072a99),
                                )),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextField(
                            controller: reasonController,
                            cursorColor: const Color(0x33072a99),
                            keyboardType: TextInputType.name,
                            onSubmitted: (_) {},
                            minLines: 10,
                            maxLines: 15,
                            textInputAction: TextInputAction.done,
                            style: const TextStyle(color: Color(0xff072a99)),
                            decoration: InputDecoration(
                              fillColor: const Color(0x33072a99),
                              filled: true,
                              hintText: "State your reason here",
                              contentPadding: const EdgeInsets.all(10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        btnval == 'show'
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (reasonController.text != '') {
                                            btnval = 'show';
                                            wfh();
                                          } else if (reasonController.text ==
                                              '') {
                                            Fluttertoast.showToast(
                                                msg:
                                                    "Please fill all the fields",
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.BOTTOM,
                                                timeInSecForIosWeb: 2,
                                                backgroundColor: Colors.white,
                                                textColor: Colors.black,
                                                fontSize: 16.0);
                                          }
                                        },
                                        style: ButtonStyle(
                                          padding: WidgetStateProperty.all(
                                              const EdgeInsets.all(15)),
                                          shape: WidgetStateProperty.all(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10))),
                                          backgroundColor:
                                              WidgetStateProperty.all(
                                            const Color(0xff072a99),
                                          ),
                                          elevation: WidgetStateProperty.all(8),
                                        ),
                                        child: const Text("Submit"),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      //bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }
}
