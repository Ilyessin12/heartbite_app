-- Schema for HeartBite App in PostgreSQL (Supabase)

-- Drop existing tables (hati-hati: akan menghapus semua data)
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS recipe_ratings CASCADE;
DROP TABLE IF EXISTS comment_likes CASCADE;
DROP TABLE IF EXISTS recipe_comments CASCADE;
DROP TABLE IF EXISTS recipe_bookmarks CASCADE;
DROP TABLE IF EXISTS bookmark_folders CASCADE;
DROP TABLE IF EXISTS recipe_likes CASCADE;
DROP TABLE IF EXISTS recipe_gallery_images CASCADE;
DROP TABLE IF EXISTS recipe_equipment CASCADE;
DROP TABLE IF EXISTS recipe_instructions CASCADE;
DROP TABLE IF EXISTS recipe_ingredients CASCADE;
DROP TABLE IF EXISTS recipe_diet_programs CASCADE;
DROP TABLE IF EXISTS recipe_categories CASCADE;
DROP TABLE IF EXISTS recipes CASCADE;
DROP TABLE IF EXISTS ingredient_allergens CASCADE;
DROP TABLE IF EXISTS user_missing_equipment CASCADE;
DROP TABLE IF EXISTS user_diet_programs CASCADE;
DROP TABLE IF EXISTS user_allergens CASCADE;
DROP TABLE IF EXISTS ingredients CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS equipment CASCADE;
DROP TABLE IF EXISTS allergens CASCADE;
DROP TABLE IF EXISTS diet_programs CASCADE;
DROP TABLE IF EXISTS user_follows CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Rebuild tables with correct types

-- users table (UUID primary key)
CREATE TABLE users(
    id UUID PRIMARY KEY,
    full_name TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    password_hash TEXT,
    profile_picture TEXT,
    cover_picture TEXT,
    bio TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- user_follows table (UUID foreign keys)
CREATE TABLE user_follows(
    id SERIAL PRIMARY KEY,
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(follower_id, following_id)
);

-- diet_programs table
CREATE TABLE diet_programs(
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- allergens table
CREATE TABLE allergens(
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- equipment table
CREATE TABLE equipment(
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- categories table
CREATE TABLE categories(
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ingredients table
CREATE TABLE ingredients(
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    unit TEXT,
    category TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- user_allergens table
CREATE TABLE user_allergens(
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    allergen_id INTEGER NOT NULL REFERENCES allergens(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, allergen_id)
);

-- user_diet_programs table
CREATE TABLE user_diet_programs(
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    diet_program_id INTEGER NOT NULL REFERENCES diet_programs(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, diet_program_id)
);

-- user_missing_equipment table
CREATE TABLE user_missing_equipment(
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    equipment_id INTEGER NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, equipment_id)
);

-- ingredient_allergens table
CREATE TABLE ingredient_allergens(
    id SERIAL PRIMARY KEY,
    ingredient_id INTEGER NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    allergen_id INTEGER NOT NULL REFERENCES allergens(id) ON DELETE CASCADE,
    UNIQUE(ingredient_id, allergen_id)
);

-- recipes table
CREATE TABLE recipes(
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    calories INTEGER,
    servings INTEGER NOT NULL DEFAULT 1,
    cooking_time_minutes INTEGER NOT NULL,
    difficulty_level TEXT DEFAULT 'medium',
    is_published BOOLEAN DEFAULT TRUE,
    rating REAL DEFAULT 0.0,
    review_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT difficulty_level_check CHECK(difficulty_level IN ('easy', 'medium', 'hard'))
);

-- recipe_categories table
CREATE TABLE recipe_categories(
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    UNIQUE(recipe_id, category_id)
);

-- recipe_diet_programs table
CREATE TABLE recipe_diet_programs(
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    diet_program_id INTEGER NOT NULL REFERENCES diet_programs(id) ON DELETE CASCADE,
    UNIQUE(recipe_id, diet_program_id)
);

-- recipe_ingredients table
CREATE TABLE recipe_ingredients(
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    ingredients TEXT NOT NULL,
    quantity REAL NOT NULL,
    unit TEXT,
    notes TEXT,
    order_index INTEGER DEFAULT 0
);

-- recipe_instructions table
CREATE TABLE recipe_instructions(
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    step_number INTEGER NOT NULL,
    instruction TEXT NOT NULL,
    image_url TEXT,
    estimated_time_minutes INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(recipe_id, step_number)
);

-- recipe_equipment table
CREATE TABLE recipe_equipment(
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    equipment_id INTEGER NOT NULL REFERENCES equipment(id) ON DELETE RESTRICT,
    is_required BOOLEAN DEFAULT TRUE,
    notes TEXT,
    UNIQUE(recipe_id, equipment_id)
);

-- recipe_gallery_images table
CREATE TABLE recipe_gallery_images(
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    caption TEXT,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- recipe_likes table
CREATE TABLE recipe_likes(
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(recipe_id, user_id)
);

-- bookmark_folders table
CREATE TABLE bookmark_folders(
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, name)
);

-- recipe_bookmarks table
CREATE TABLE recipe_bookmarks(
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    folder_id INTEGER NOT NULL REFERENCES bookmark_folders(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(recipe_id, user_id, folder_id)
);

-- recipe_comments table
CREATE TABLE recipe_comments(
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_comment_id INTEGER REFERENCES recipe_comments(id) ON DELETE CASCADE,
    comment TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- comment_likes table
CREATE TABLE comment_likes(
    id SERIAL PRIMARY KEY,
    comment_id INTEGER NOT NULL REFERENCES recipe_comments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(comment_id, user_id)
);

-- recipe_ratings table
CREATE TABLE recipe_ratings(
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating_value INTEGER NOT NULL,
    review_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(recipe_id, user_id),
    CONSTRAINT rating_value_check CHECK(rating_value >= 1 AND rating_value <= 5)
);

-- notifications table
CREATE TABLE notifications(
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    actor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    target_id INTEGER,
    target_type TEXT,
    message TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT notification_type_check CHECK(type IN ('follow', 'like_recipe', 'comment', 'like_comment', 'reply', 'new_recipe', 'rating'))
);

-- Indexes
CREATE INDEX idx_recipes_cooking_time ON recipes(cooking_time_minutes);
CREATE INDEX idx_recipes_created_at ON recipes(created_at);
CREATE INDEX idx_recipes_title_published ON recipes(title, is_published);
CREATE INDEX idx_recipes_user_created ON recipes(user_id, created_at);
CREATE INDEX idx_recipe_bookmarks_user_folder ON recipe_bookmarks(user_id, folder_id);
CREATE INDEX idx_recipe_comments_recipe_created ON recipe_comments(recipe_id, created_at);
CREATE INDEX idx_recipe_comments_parent ON recipe_comments(parent_comment_id);
CREATE INDEX idx_user_follows_following_follower ON user_follows(following_id, follower_id);
CREATE INDEX idx_notifications_user_read_created ON notifications(user_id, is_read, created_at);
CREATE INDEX idx_recipe_gallery_recipe_id ON recipe_gallery_images(recipe_id, order_index);
CREATE INDEX idx_recipe_ratings_recipe_user ON recipe_ratings(recipe_id, user_id);