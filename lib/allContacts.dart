import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'controller.dart';

class AllContacts extends StatefulWidget {
  const AllContacts({super.key});

  @override
  State<AllContacts> createState() => _AllContactsState();
}

class _AllContactsState extends State<AllContacts> {
  List<Map<String, dynamic>> _contactList = [];

  // ignore: unused_field
  bool _isLoading = true;

  void _refreshContacts() async {
    final data = await Controller.getContacts();

    setState(() {
      _contactList = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshContacts();
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  Uint8List _profilePic = Uint8List(0);

  Future<void> _addContact() async {
    await Controller.createContact(
      _nameController.text,
      _telephoneController.text,
      _emailController.text,
      _streetController.text,
      base64Encode(_profilePic),
    );
    _refreshContacts();
        ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact Added'),
        behavior: SnackBarBehavior.floating,
      ),
        );
  }

  Future<void> _updateContact(int id) async {
    await Controller.updateContact(
        id,
        _nameController.text,
        _telephoneController.text,
        _emailController.text,
        _streetController.text,
        base64Encode(_profilePic),
        );
    _refreshContacts();
        ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact Updated'),
        behavior: SnackBarBehavior.floating,
      ),
        );
  }

  Future<void> _deleteContact(int id) async {
    await Controller.deleteContact(id);
    // showSnackBar('Contact deleted successfully');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact Deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _refreshContacts();
  }

  void _showForm(int? id) async {
    if (id != null) {
      final existingContactList =
          _contactList.firstWhere((element) => element['id'] == id);
      _nameController.text = existingContactList['name'];
      _telephoneController.text = existingContactList['telephone'];
      _emailController.text = existingContactList['email'];
      _streetController.text = existingContactList['street'];
      _profilePic = base64Decode(existingContactList['profilePic']);
    } else {
      _nameController.text = '';
      _telephoneController.text = '';
      _emailController.text = '';
      _streetController.text = '';
      _profilePic = Uint8List(0);
    }

    // validate data before submitting
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom + 120,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _profilePic.isNotEmpty
                        ? MemoryImage(_profilePic)
                        : const AssetImage('assets/defaultPic.png')
                            as ImageProvider,
                  ),
                  onTap: () async {
                    final pickedFile = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);

                    if (pickedFile != null) {
                      setState(() {
                        _profilePic = File(pickedFile.path).readAsBytesSync();
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name can\'t be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _telephoneController,
                  decoration: const InputDecoration(hintText: 'Telephone'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Telephone can\'t be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(hintText: 'Email'),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Invalid email';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _streetController,
                  decoration: const InputDecoration(hintText: 'Street'),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return null;
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (id == null) {
                        await _addContact();
                      }
                      if (id != null) {
                        await _updateContact(id);
                      }
                      // create the text fields
                      _nameController.text = '';
                      _telephoneController.text = '';
                      _emailController.text = '';
                      _streetController.text = '';
                      // close
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(id == null ? 'Create New' : 'Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
      ),
      body: ListView.builder(
        itemCount: _contactList.length,
        itemBuilder: (context, index) => Card(
          color: Colors.deepPurple[50],
          margin: const EdgeInsets.all(5),
          child: ListTile(
            leading: SizedBox(
              width: 50,
              height: 50,
              child: CircleAvatar(
                backgroundImage: _contactList[index]['profilePic'].isNotEmpty
                    ? MemoryImage(
                        base64Decode(_contactList[index]['profilePic']))
                    : const AssetImage('assets/defaultPic.png')
                        as ImageProvider,
              ),
            ),
            title: Text(_contactList[index]['name']),
            subtitle: Text(_contactList[index]['telephone']),
            trailing: SizedBox(
              width: 100,
              child: Row(children: [
                IconButton(
                  onPressed: () => _showForm(_contactList[index]['id']),
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Deletion'),
                        content: const Text(
                            'Are you sure you want to delete this contact?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              _deleteContact(_contactList[index]['id']);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  ),
                  icon: const Icon(Icons.delete),
                ),
              ]),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
