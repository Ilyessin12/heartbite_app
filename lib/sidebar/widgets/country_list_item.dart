import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CountryListItem extends StatelessWidget {
  final String name;
  final String flagUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const CountryListItem({
    super.key,
    required this.name,
    required this.flagUrl,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  // Widget build(BuildContext context) {
  //   return InkWell(
  //     onTap: onTap,
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //       decoration: const BoxDecoration(
  //         border: Border(
  //           bottom: BorderSide(
  //             color: AppColors.grayLight,
  //             width: 1,
  //           ),
  //         ),
  //       ),
  //       child: Row(
  //         children: [
  //           CircleAvatar(
  //             radius: 12,
  //             backgroundImage: NetworkImage(flagUrl),
  //           ),
  //           const SizedBox(width: 12),
  //           Text(
  //             name,
  //             style: const TextStyle(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w400,
  //             ),
  //           ),
  //           if (isSelected) ...[
  //             const Spacer(),
  //             const Icon(
  //               Icons.check,
  //               color: AppColors.primary,
  //               size: 20,
  //             ),
  //           ],
  //         ],
  //       ),
  //     ),
  //   );
  // }

Widget build(BuildContext context) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Padding kiri 12px
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.grayLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Gambar bendera menggunakan ClipOval
          ClipOval(
            child: Image.network(
              flagUrl,
              width: 16, // Ukuran gambar 16x16 px
              height: 16, // Ukuran gambar 16x16 px
              fit: BoxFit.cover, // Memastikan gambar tidak meluap
            ),
          ),
          const SizedBox(width: 12), // Memberikan jarak antara gambar dan teks
          // Teks nama negara dengan Flexible
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                overflow: TextOverflow.ellipsis, // Tambahkan elipsis jika teks panjang
              ),
              maxLines: 1, // Membatasi teks hanya satu baris
            ),
          ),
          // Ceklis di pojok kanan
          if (isSelected)
            const Icon(
              Icons.check,
              color: AppColors.primary,
              size: 20,
            ),
        ],
      ),
    ),
  );
}



}
