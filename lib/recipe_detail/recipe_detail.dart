import 'models/recipe.dart';
import 'models/ingredient.dart';
import 'models/direction.dart';
import 'models/comment.dart';


// Make this a top-level function so it can be imported and used elsewhere
Recipe getSampleRecipe() {
  return Recipe(
    id: '1',
    authorId: 'sample_author_id', // Added placeholder authorId
    title: 'Sandwich dengan telur rebus',
    imageUrl: 'assets/images/recipes/sandwich1.jpg',
    rating: 4.5,
    reviewCount: 128,
    authorName: 'Amelia Melanes',
    authorRecipeCount: 23,
    calories: 23,
    portions: '1-2',
    cookingMinutes: 12,
    ingredients: [
      Ingredient(
        order: 1,
        name: 'Telur',
        amount: '250',
        unit: 'g',
      ),
      Ingredient(
        order: 2,
        name: 'Roti',
        amount: '2',
        unit: 'potong',
      ),
      Ingredient(
        order: 3,
        name: 'Mayones',
        amount: '2',
        unit: 'sdm',
      ),
      Ingredient(
        order: 4,
        name: 'Selada',
        amount: '1',
        unit: 'lembar',
      ),
    ],
    directions: [
      Direction(
        order: 1,
        description: 'Potong telur menjadi kecil-kecil',
      ),
      Direction(
        order: 2,
        description: 'Campurkan mayones, jus lemon, mustard, garam, dan merica dalam mangkuk sedang',
        imageUrl: 'assets/images/ingredients/mixing_bowl.jpg',
      ),
      Direction(
        order: 3,
        description: 'Tambahkan telur cincang, seledri, dan daun bawang; aduk rata',
      ),
      Direction(
        order: 4,
        description: 'Simpan di kulkas, tutup untuk mencampur rasa',
      ),
    ],
    galleryImages: [
      'assets/images/recipes/sandwich1.jpg',
      'assets/images/recipes/sandwich2.jpg',
      'assets/images/recipes/sandwich3.jpg',
      'assets/images/recipes/sandwich4.jpg',
      'assets/images/recipes/sandwich5.jpg',
      'assets/images/recipes/sandwich6.jpg',
      'assets/images/recipes/sandwich7.jpg',
      'assets/images/recipes/sandwich8.jpg',
    ],
    comments: [
      Comment(
        id: '1',
        userName: 'Antonio',
        userImageUrl: 'assets/images/avatars/avatar5.jpg',
        text: 'Resepnya enak banget! Saya coba tadi pagi dan keluarga suka. Makasih ya!',
        timeAgo: '1 hari lalu',
        likeCount: 32,
      ),
      Comment(
        id: '2',
        userName: 'Melanie Rose',
        userImageUrl: 'assets/images/avatars/avatar1.jpg',
        text: 'Saya ganti mayones dengan yogurt dan rasanya tetap enak. Lebih sehat juga!',
        timeAgo: '2 jam lalu',
        likeCount: 424,
      ),
      Comment(
        id: '3',
        userName: 'Jonathan Jose',
        userImageUrl: 'assets/images/avatars/avatar2.jpg',
        text: 'Boleh tambah sedikit paprika untuk rasa yang lebih segar. Rekomendasi!',
        timeAgo: '5 jam lalu',
        likeCount: 25,
      ),
      Comment(
        id: '4',
        userName: 'Nicky',
        userImageUrl: 'assets/images/avatars/avatar3.jpg',
        text: 'Anak-anak suka banget. Mereka minta dibuatkan lagi besok pagi.',
        timeAgo: '1 hari lalu',
        likeCount: 142,
      ),
      Comment(
        id: '5',
        userName: 'Moon Star',
        userImageUrl: 'assets/images/avatars/avatar4.jpg',
        text: 'Saya coba tambahkan sedikit alpukat, jadi lebih creamy. Cobain deh!',
        timeAgo: '2 hari lalu',
        likeCount: 82,
      ),
      Comment(
        id: '6',
        userName: 'Melanie',
        userImageUrl: 'assets/images/avatars/avatar5.jpg',
        text: 'Ini jadi sarapan favorit saya sekarang. Simple dan enak!',
        timeAgo: '3 hari lalu',
        likeCount: 86,
      ),
    ],
  );
}