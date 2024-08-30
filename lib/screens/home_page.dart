// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Initialize Firestore instance
  FirebaseFirestore db = FirebaseFirestore.instance;
  // List to store task names
  final List<String> tasks = <String>[];
  // List to store checkbox states
  final List<bool> checkboxes = List.generate(8, (index) => false);
  // Text controller for task input field
  TextEditingController nameController = TextEditingController();
  // Flag to track checkbox state
  bool isChecked = false;
// Asynchronous function to update the user connect and add another task to Firestore
  void addItemToList() async {
    // Get the task name from the input field
    final String taskName = nameController.text;

    if (taskName != '') {
      // Add a server-generated timestamp to the task and add it to Firestore.
      await db.collection('tasks').add({
        'name': taskName,
        'completed': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
// Update the UI by inserting the new task
      setState(() {
        tasks.insert(0, taskName);
        checkboxes.insert(0, false);
      });
    }
  }

  // Asynchronous function to remove a task from Firestore
  void removeItems(int index) async {
    //Get the tasks to be removed
    String taskToBeRemoved = tasks[index];

    //Remove the task from Firestore
    QuerySnapshot querySnapshot = await db
        .collection('tasks')
        .where('name', isEqualTo: taskToBeRemoved)
        .get();

    if (querySnapshot.size > 0) {
      DocumentSnapshot documentSnapshot = querySnapshot.docs[0];

      await documentSnapshot.reference.delete();
    }
// Update the UI by removing the task
    setState(() {
      tasks.removeAt(index);
      checkboxes.removeAt(index);
    });
  }

  // Asynchronous function to fetch tasks from Firestore
  Future<void> fetchTasksFromFirestore() async {
    //Get a reference to the 'tasks' collection from Firestore
    CollectionReference tasksCollection = db.collection('tasks');

    //Fetch the documents (tasks) from the collection
    QuerySnapshot querySnapshot = await tasksCollection.get();

    //Create an empty list to store the fetched task names
    List<String> fetchedTasks = [];

    //Look through each doc (task) in the querySnapshot object
    for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
      //Get the task name from the data
      String taskName = docSnapshot.get('name');

      //Get the completion status from the data
      docSnapshot.get('completed');

      //Add the tasks to the fetched tasks
      fetchedTasks.add(taskName);
    }
    setState(() {
      tasks.clear();
      tasks.addAll(fetchedTasks);
    });
  }

// Asynchronous function to update the completion status of a task
  Future<void> updateTaskCompletionStatus(
      String taskName, bool completed) async {
    //Get a reference to the 'tasks' collection from Firestore
    CollectionReference tasksCollection = db.collection('tasks');

    //Query firestore for tasks with the given task name
    QuerySnapshot querySnapshot =
        await tasksCollection.where('name', isEqualTo: taskName).get();

    //if matching document is found
    if (querySnapshot.size > 0) {
      //Getting a reference to the first matching document
      DocumentSnapshot documentSnapshot = querySnapshot.docs[0];

      await documentSnapshot.reference.update({'completed': completed});
    }

    setState(() {
      //find the index of the task in the task list
      int taskIndex = tasks.indexWhere((task) => task == taskName);

      //Update the corresponding checkbox value in the the checkbox list
      checkboxes[taskIndex] = completed;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchTasksFromFirestore();
  }

  // Function to clear the input field
  void clearInput() {
    setState(() {
      nameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: 80,
              child: Image.asset('assets/rdplogo.png'),
            ),
            const Text(
              'Daily Planner',
              style: TextStyle(
                  fontFamily: 'Caveat', fontSize: 32, color: Colors.white),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar(
              calendarFormat: CalendarFormat.month,
              headerVisible: true,
              focusedDay: DateTime.now(),
              firstDay: DateTime(2023),
              lastDay: DateTime(2025),
            ),
            // ignore: sized_box_for_whitespace
            Container(
              height: 280,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tasks.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    margin: const EdgeInsets.only(top: 3.0),
                    decoration: BoxDecoration(
                      color: checkboxes[index]
                          ? Colors.green.withOpacity(0.7)
                          : Colors.blue.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            size: 44,
                            !checkboxes[index]
                                ? Icons.manage_history
                                : Icons.playlist_add_check_circle,
                          ),
                          // ignore: duplicate_ignore
                          // ignore: prefer_const_constructors
                          SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              tasks[index],
                              style: checkboxes[index]
                                  ? TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: 25,
                                      color: Colors.black.withOpacity(0.5),
                                    )
                                  // ignore: duplicate_ignore
                                  // ignore: prefer_const_constructors
                                  : TextStyle(fontSize: 25),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Row(
                            children: [
                              Transform.scale(
                                scale: 1.4,
                                child: Checkbox(
                                    value: checkboxes[index],
                                    onChanged: (newValue) {
                                      setState(() {
                                        checkboxes[index] = newValue!;
                                      });
                                      updateTaskCompletionStatus(
                                          tasks[index], newValue!);
                                    }),
                              ),
                              IconButton(
                                color: Colors.black,
                                iconSize: 30,
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  removeItems(index);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 20),
                    child: TextField(
                      controller: nameController,
                      maxLength: 20,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(23),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelText: 'Add To-Do List Item',
                        labelStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                        hintText: 'Enter your task here',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: null,
                  //To-Do clearTextField()
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(4.0),
              child: ElevatedButton(
                onPressed: () {
                  addItemToList();
                  clearInput();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.blue),
                ),
                child: Text(
                  'Add To-Do List Item',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
