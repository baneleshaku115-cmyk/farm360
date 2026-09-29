import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'admin_notify.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('income');
  await Hive.openBox('expenses');
  await Hive.openBox('loss');
  await Hive.openBox('stock');
  await Hive.openBox('equipment');
  await Hive.openBox('marketplace');
  await Hive.openBox('settings');
  runApp(Farm360App());
}

class Farm360App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Farm360',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  var incomeBox = Hive.box('income');
  var expenseBox = Hive.box('expenses');
  var lossBox = Hive.box('loss');
  var stockBox = Hive.box('stock');
  var equipBox = Hive.box('equipment');
  int tab = 0;

  @override
  void initState() {
    super.initState();
    AdminNotify.newDownload();
  }

  double getTotal(Box box) {
    double t = 0;
    for (var e in box.values) {
      if (e['amount']!= null) t += (e['amount'] as num).toDouble();
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    double income = getTotal(incomeBox);
    double expenses = getTotal(expenseBox);
    double loss = getTotal(lossBox);
    double profit = income - expenses - loss;
    double totalCost = expenses + loss;
    double budget = 5000;

    return Scaffold(
      backgroundColor: Color(0xFFF5F7F5),
      appBar: AppBar(title: Text('🌿 Farm360 - By Banele 15'), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
      body: tab == 0? buildDashboard(income, expenses, loss, profit, totalCost, budget)
           : tab == 1? buildListScreen('Income', incomeBox)
           : tab == 2? buildListScreen('Expenses', expenseBox)
           : tab == 3? buildStockScreen()
           : buildEquipmentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        onTap: (i) => setState(() => tab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[700],
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.arrow_upward), label: 'Income'),
          BottomNavigationBarItem(icon: Icon(Icons.arrow_downward), label: 'Expenses'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Equip'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green[700],
        onPressed: () => showAddDialog(),
        label: Text('+ Add', style: TextStyle(color: Colors.white)),
        icon: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget buildDashboard(double income, double expenses, double loss, double profit, double totalCost, double budget) {
    return ListView(padding: EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(child: card('Income', 'R ${income.toStringAsFixed(0)}', Colors.green[50]!, Icons.arrow_upward)),
        SizedBox(width: 10),
        Expanded(child: card('Expenses', 'R ${expenses.toStringAsFixed(0)}', Colors.orange[50]!, Icons.arrow_downward)),
      ]),
      SizedBox(height: 10),
      Row(children: [
        Expanded(child: card('Loss', 'R ${loss.toStringAsFixed(0)}', Colors.red[50]!, Icons.warning)),
        SizedBox(width: 10),
        Expanded(child: card('Profit', 'R ${profit.toStringAsFixed(0)}', Colors.green[100]!, Icons.account_balance_wallet)),
      ]),
      SizedBox(height: 16),
      Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Budget R${budget.toStringAsFixed(0)} - Used ${(totalCost/budget*100).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        LinearProgressIndicator(value: (totalCost/budget).clamp(0,1), color: Colors.green, minHeight: 10),
        SizedBox(height: 12),
        Text('Budget Shop:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
        budgetItem('Chicken Feed 25kg', 420, budget-totalCost),
        budgetItem('Fertilizer 10kg', 950, budget-totalCost),
      ])),
    ]);
  }

  Widget budgetItem(String name, double price, double remaining) {
    bool can = price <= remaining;
    return Container(margin: EdgeInsets.only(top: 8), padding: EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: can? Colors.green[200]!: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(name), Text(can? 'R$price - Can Buy':'No budget', style: TextStyle(fontWeight: FontWeight.bold, color: can? Colors.green[700]: Colors.grey))]));
  }

  Widget card(String t, String v, Color bg, IconData icon) {
    return Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 18), SizedBox(width: 6), Text(t)]), SizedBox(height: 8), Text(v, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))]));
  }

  Widget buildListScreen(String title, Box box) {
    return ValueListenableBuilder(valueListenable: box.listenable(), builder: (ctx, b, _) {
      var items = b.values.toList().reversed.toList();
      if(items.isEmpty) return Center(child: Text('No $title yet'));
      return ListView.builder(padding: EdgeInsets.all(12), itemCount: items.length, itemBuilder: (ctx,i){ var it=items[i]; return Card(child: ListTile(title: Text(it['type']), subtitle: Text('${it['note']} • ${it['date']}'), trailing: Text('R ${it['amount']}', style: TextStyle(fontWeight: FontWeight.bold))));});
    });
  }

  Widget buildStockScreen() {
    return ValueListenableBuilder(valueListenable: stockBox.listenable(), builder: (ctx, b, _) {
      var items = b.values.toList();
      if(items.isEmpty) return Center(child: Text('No stock yet'));
      return ListView.builder(padding: EdgeInsets.all(12), itemCount: items.length, itemBuilder: (ctx,i){ var it=items[i]; return Card(child: ListTile(leading: CircleAvatar(child: Text(it['type'][0])), title: Text(it['type']), subtitle: Text('${it['qty']} animals'), trailing: Text('R ${it['price']}')));});
    });
  }

  Widget buildEquipmentScreen() {
    return ValueListenableBuilder(valueListenable: equipBox.listenable(), builder: (ctx, b, _) {
      var items = b.values.toList();
      if(items.isEmpty) return Center(child: Text('No equipment'));
      return ListView.builder(padding: EdgeInsets.all(12), itemCount: items.length, itemBuilder: (ctx,i){ var it=items[i]; return Card(child: ListTile(leading: Icon(Icons.build), title: Text(it['type']), subtitle: Text('Good • Available')));});
    });
  }

  void showAddDialog() {
    String type = 'Sold Chickens'; String qty=''; String amount=''; String note='';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Add'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(decoration: InputDecoration(labelText: 'Type e.g Sold Chickens'), onChanged: (v)=> type=v),
        TextField(decoration: InputDecoration(labelText: 'Amount R / Qty'), keyboardType: TextInputType.number, onChanged: (v)=> amount=v),
        TextField(decoration: InputDecoration(labelText: 'Note'), onChanged: (v)=> note=v),
      ]),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(ctx), child: Text('Cancel')),
        ElevatedButton(onPressed: (){
          var uuid=Uuid().v4();
          var data={'id':uuid,'type':type,'amount':double.tryParse(amount)??0,'qty':int.tryParse(amount)??0,'price':double.tryParse(amount)??0,'note':note,'date':DateTime.now().toString().substring(0,16)};
          if(tab==1) incomeBox.put(uuid,data); else if(tab==2) expenseBox.put(uuid,data); else if(tab==3) stockBox.put(uuid,{'type':type,'qty':int.tryParse(amount)??0,'price':100,'date':data['date']}); else if(tab==4) equipBox.put(uuid,{'type':type}); else incomeBox.put(uuid,data);
          setState((){}); Navigator.pop(ctx);
        }, child: Text('Save')),
      ],
    ));
  }
}
