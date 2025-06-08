import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<Settings> {
  final nameController = TextEditingController(text: 'Mudeen Mohomad');
  final contactController = TextEditingController(text: '+94 76834778');
  final addressController = TextEditingController(text: 'kurunegala');
  final address2Controller = TextEditingController(text: 'Apt 4B');
  final cityController = TextEditingController(text: 'Kurunegala');
  final provinceController = TextEditingController(text: 'North Western');
  final postalCodeController = TextEditingController(text: '60410');

  int _selectedIndex = 3;

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    addressController.dispose();
    address2Controller.dispose();
    cityController.dispose();
    provinceController.dispose();
    postalCodeController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/cart');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/orders');
        break;
      case 3:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/images/icon2.png',
              width: 40,
              height: 40,
              errorBuilder:
                  (context, error, stackTrace) => const Icon(Icons.error),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/cart');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/icon1.png',
                      width: 30,
                      height: 30,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.error),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage('assets/icons/icon1.png'),
                ),
              ],
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: buildForm(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget buildForm() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Settings',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        const Text(
          'Profile Picture',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/images/profile_pic.png'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
              ),
              child: Text(
                'Change Picture',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        buildTextField('Full Name', nameController),
        const SizedBox(height: 16),
        buildTextField(
          'Phone Number',
          contactController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        buildTextField('Address', addressController, maxLines: 3),
        const SizedBox(height: 16),
        buildTextField('Address Line 2', address2Controller, maxLines: 2),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(child: buildTextField('City', cityController)),
            const SizedBox(width: 16),
            Expanded(child: buildTextField('Province', provinceController)),
          ],
        ),

        SizedBox(height: 16),
        buildTextField('Postal Code', postalCodeController),

        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile Saved (not really)')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 3,
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Text(
                'Save Changes',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
