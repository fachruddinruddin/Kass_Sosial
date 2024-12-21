import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kass_sosial/components/appbar.dart';
import 'package:kass_sosial/config/constant.dart';
import 'package:kass_sosial/models/report.dart';
import 'package:kass_sosial/models/transaction.dart';
import 'package:kass_sosial/services/reports_manager.dart';
import 'package:kass_sosial/services/transaction_manager.dart';

class NewTransactionScreen extends StatefulWidget {
  const NewTransactionScreen({Key? key}) : super(key: key);

  @override
  _NewTransactionScreenState createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController catatanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  TransactionType _type = TransactionType.Pemasukan;

  @override
  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar("Tambah transaksi baru"),
      body: Padding(
        padding: EdgeInsets.all(12.0),
        child: CustomScrollView(
          shrinkWrap: false,
          slivers: [
            SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(children: [
                  TextFormField(
                    controller: nameController,
                    key: Key("nama"),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Mohon untuk diisi!';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                        labelText: "Nama transaksi",
                        hintText: "contoh: Beli sabun"),
                    keyboardType: TextInputType.text,
                  ),
                  TextFormField(
                    controller: qtyController,
                    key: Key("qty"),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty || double.tryParse(value) == null || double.parse(value) < 0) {
                        return 'Mohon untuk diisi dengan angka yang valid!';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                        labelText: "Qty", hintText: "contoh: 5"),
                    keyboardType: TextInputType.numberWithOptions(
                        decimal: true, signed: false),
                  ),
                  DropdownButtonFormField<TransactionType>(
                      key: Key("type"),
                      onSaved: (TransactionType? value) {
                        if (value != null) {
                          _type = value;
                        }
                      },
                      value: _type,
                      onChanged: (TransactionType? value) {
                        if (value != null) {
                          setState(() {
                            _type = value;
                          });
                        }
                      },
                      items: [
                        DropdownMenuItem(
                            value: TransactionType.Pemasukan,
                            child: Text(TransactionType.Pemasukan.toString()
                                .replaceAll('TransactionType.', ''))),
                        DropdownMenuItem(
                            value: TransactionType.Pengeluaran,
                            child: Text(TransactionType.Pengeluaran.toString()
                                .replaceAll('TransactionType.', '')))
                      ]),
                  TextFormField(
                    controller: priceController,
                    key: Key("price"),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty || int.tryParse(value.replaceAll(',', '')) == null) {
                        return 'Mohon untuk diisi dengan angka yang valid!';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                        labelText: "Harga satuan",
                        hintText: "contoh: 5000",
                        prefix: Text("Rp")),
                    keyboardType: TextInputType.number,
                    onChanged: (newValue) {
                      if (newValue.isNotEmpty) {
                        var price = int.parse(newValue.replaceAll(',', ''));
                        var comma = NumberFormat('###,###');
                        var newString = comma.format(price);
                        int selectionIndex = newValue.length - priceController.selection.extentOffset;
                        priceController.text = newString;
                        priceController.selection = TextSelection.collapsed(
                            offset: newString.length - selectionIndex);
                      }
                    },
                  ),
                  TextFormField(
                    controller: catatanController,
                    key: Key("catatan"),
                    decoration: InputDecoration(
                        labelText: "Catatan",
                        hintText: "contoh: Beli di warungnya si Fulan buat mandi"),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                  ),
                ]),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                      onPressed: onBtnSubmitPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primarySolid,
                        minimumSize: Size(MediaQuery.of(context).size.width, 40),
                      ),
                      child: Text("Tambahkan"))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void onBtnSubmitPressed() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      DateTime curTime = DateTime.now();
      Transaction transaction = Transaction(
          name: nameController.text,
          description: catatanController.text,
          price: int.parse(priceController.text.replaceAll(',', '')),
          qty: double.parse(qtyController.text),
          type: _type,
          time: curTime);
      TransactionLocalStorage trxStorage = TransactionLocalStorage();
      TransactionManager transactionManager = TransactionManager.getInstance(trxStorage);
      transactionManager.saveTransaction(transaction);

      ReportLocalStorage reportStorage = ReportLocalStorage();
      ReportManager reportManager = ReportManager.getInstance(reportStorage);
      String month = DateFormat.MMMM("id_ID").format(curTime);
      int year = int.parse(DateFormat.y("id_ID").format(curTime));
      Map<dynamic, Report> _oldReport = await reportManager.getAt(month, year);
      if (_oldReport.isEmpty) {
        Report _newReport = Report(
            pemasukan: (_type == TransactionType.Pemasukan)
                ? (transaction.price * transaction.qty).toInt()
                : 0,
            pengeluaran: (_type == TransactionType.Pengeluaran)
                ? (transaction.price * transaction.qty).toInt()
                : 0,
            bulan: month,
            tahun: year);
        reportManager.saveReport(_newReport);
      } else {
        Report _newReport = Report(
            pemasukan: (_type == TransactionType.Pemasukan)
                ? _oldReport.values.first.pemasukan + (transaction.price * transaction.qty).toInt()
                : _oldReport.values.first.pemasukan,
            pengeluaran: (_type == TransactionType.Pengeluaran)
                ? _oldReport.values.first.pengeluaran + (transaction.price * transaction.qty).toInt()
                : _oldReport.values.first.pengeluaran,
            bulan: month,
            tahun: year);
        reportManager.updateReport(_oldReport.keys.first, _newReport);
      }
      Navigator.pop(context);
    } else {
      print("invalid!");
    }
  }
}
