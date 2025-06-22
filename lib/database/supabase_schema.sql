-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.allergens (
  id integer NOT NULL DEFAULT nextval('allergens_id_seq'::regclass),
  name text NOT NULL UNIQUE,
  description text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT allergens_pkey PRIMARY KEY (id)
);
CREATE TABLE public.bookmark_folders (
  id integer NOT NULL DEFAULT nextval('bookmark_folders_id_seq'::regclass),
  user_id uuid NOT NULL,
  name text NOT NULL,
  description text,
  is_default boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  image_url text,
  CONSTRAINT bookmark_folders_pkey PRIMARY KEY (id),
  CONSTRAINT bookmark_folders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.categories (
  id integer NOT NULL DEFAULT nextval('categories_id_seq'::regclass),
  name text NOT NULL UNIQUE,
  description text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT categories_pkey PRIMARY KEY (id)
);
CREATE TABLE public.comment_likes (
  id integer NOT NULL DEFAULT nextval('comment_likes_id_seq'::regclass),
  comment_id integer NOT NULL,
  user_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT comment_likes_pkey PRIMARY KEY (id),
  CONSTRAINT comment_likes_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.recipe_comments(id),
  CONSTRAINT comment_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.diet_programs (
  id integer NOT NULL DEFAULT nextval('diet_programs_id_seq'::regclass),
  name text NOT NULL UNIQUE,
  description text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT diet_programs_pkey PRIMARY KEY (id)
);
CREATE TABLE public.equipment (
  id integer NOT NULL DEFAULT nextval('equipment_id_seq'::regclass),
  name text NOT NULL UNIQUE,
  description text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT equipment_pkey PRIMARY KEY (id)
);
CREATE TABLE public.ingredient_allergens (
  id integer NOT NULL DEFAULT nextval('ingredient_allergens_id_seq'::regclass),
  allergen_id integer NOT NULL,
  CONSTRAINT ingredient_allergens_pkey PRIMARY KEY (id),
  CONSTRAINT ingredient_allergens_allergen_id_fkey FOREIGN KEY (allergen_id) REFERENCES public.allergens(id)
);
CREATE TABLE public.ingredients (
  id integer NOT NULL DEFAULT nextval('ingredients_id_seq'::regclass),
  name text NOT NULL UNIQUE,
  unit text,
  category text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ingredients_pkey PRIMARY KEY (id)
);
CREATE TABLE public.notifications (
  id integer NOT NULL DEFAULT nextval('notifications_id_seq'::regclass),
  user_id uuid NOT NULL,
  actor_id uuid NOT NULL,
  type text NOT NULL CHECK (type = ANY (ARRAY['follow'::text, 'like_recipe'::text, 'comment'::text, 'like_comment'::text, 'reply'::text, 'new_recipe'::text, 'rating'::text])),
  target_id integer,
  target_type text,
  message text,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT notifications_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(id)
);
CREATE TABLE public.recipe_bookmarks (
  id integer NOT NULL DEFAULT nextval('recipe_bookmarks_id_seq'::regclass),
  recipe_id integer NOT NULL,
  user_id uuid NOT NULL,
  folder_id integer NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_bookmarks_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_bookmarks_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id),
  CONSTRAINT recipe_bookmarks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT recipe_bookmarks_folder_id_fkey FOREIGN KEY (folder_id) REFERENCES public.bookmark_folders(id)
);
CREATE TABLE public.recipe_categories (
  id integer NOT NULL DEFAULT nextval('recipe_categories_id_seq'::regclass),
  recipe_id integer NOT NULL,
  category_id integer NOT NULL,
  CONSTRAINT recipe_categories_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_categories_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id),
  CONSTRAINT recipe_categories_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id)
);
CREATE TABLE public.recipe_comments (
  id integer NOT NULL DEFAULT nextval('recipe_comments_id_seq'::regclass),
  recipe_id integer NOT NULL,
  user_id uuid NOT NULL,
  parent_comment_id integer,
  comment text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_comments_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_comments_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id),
  CONSTRAINT recipe_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT recipe_comments_parent_comment_id_fkey FOREIGN KEY (parent_comment_id) REFERENCES public.recipe_comments(id)
);
CREATE TABLE public.recipe_diet_programs (
  id integer NOT NULL DEFAULT nextval('recipe_diet_programs_id_seq'::regclass),
  recipe_id integer NOT NULL,
  diet_program_id integer NOT NULL,
  CONSTRAINT recipe_diet_programs_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_diet_programs_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id),
  CONSTRAINT recipe_diet_programs_diet_program_id_fkey FOREIGN KEY (diet_program_id) REFERENCES public.diet_programs(id)
);
CREATE TABLE public.recipe_equipment (
  id integer NOT NULL DEFAULT nextval('recipe_equipment_id_seq'::regclass),
  recipe_id integer NOT NULL,
  equipment_id integer NOT NULL,
  is_required boolean DEFAULT true,
  notes text,
  CONSTRAINT recipe_equipment_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_equipment_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id),
  CONSTRAINT recipe_equipment_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipment(id)
);
CREATE TABLE public.recipe_gallery_images (
  id integer NOT NULL DEFAULT nextval('recipe_gallery_images_id_seq'::regclass),
  recipe_id integer NOT NULL,
  image_url text NOT NULL,
  caption text,
  order_index integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_gallery_images_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_gallery_images_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id)
);
CREATE TABLE public.recipe_ingredients (
  id integer NOT NULL DEFAULT nextval('recipe_ingredients_id_seq'::regclass),
  recipe_id integer NOT NULL,
  quantity real NOT NULL,
  unit text,
  notes text,
  order_index integer DEFAULT 0,
  ingredients text NOT NULL,
  CONSTRAINT recipe_ingredients_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_ingredients_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id)
);
CREATE TABLE public.recipe_instructions (
  id integer NOT NULL DEFAULT nextval('recipe_instructions_id_seq'::regclass),
  recipe_id integer NOT NULL,
  step_number integer NOT NULL,
  instruction text NOT NULL,
  image_url text,
  estimated_time_minutes integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_instructions_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_instructions_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id)
);
CREATE TABLE public.recipe_likes (
  id integer NOT NULL DEFAULT nextval('recipe_likes_id_seq'::regclass),
  recipe_id integer NOT NULL,
  user_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_likes_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_likes_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id),
  CONSTRAINT recipe_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.recipe_ratings (
  id integer NOT NULL DEFAULT nextval('recipe_ratings_id_seq'::regclass),
  recipe_id integer NOT NULL,
  user_id uuid NOT NULL,
  rating_value integer NOT NULL CHECK (rating_value >= 1 AND rating_value <= 5),
  review_text text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_ratings_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_ratings_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id),
  CONSTRAINT recipe_ratings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.recipes (
  id integer NOT NULL DEFAULT nextval('recipes_id_seq'::regclass),
  user_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  image_url text,
  calories integer,
  servings integer NOT NULL DEFAULT 1,
  cooking_time_minutes integer NOT NULL,
  difficulty_level text DEFAULT 'medium'::text CHECK (difficulty_level = ANY (ARRAY['easy'::text, 'medium'::text, 'hard'::text])),
  is_published boolean DEFAULT true,
  rating real DEFAULT 0.0,
  review_count integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipes_pkey PRIMARY KEY (id),
  CONSTRAINT recipes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.user_allergens (
  id integer NOT NULL DEFAULT nextval('user_allergens_id_seq'::regclass),
  user_id uuid NOT NULL,
  allergen_id integer NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_allergens_pkey PRIMARY KEY (id),
  CONSTRAINT user_allergens_allergen_id_fkey FOREIGN KEY (allergen_id) REFERENCES public.allergens(id),
  CONSTRAINT user_allergens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.user_diet_programs (
  id integer NOT NULL DEFAULT nextval('user_diet_programs_id_seq'::regclass),
  user_id uuid NOT NULL,
  diet_program_id integer NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_diet_programs_pkey PRIMARY KEY (id),
  CONSTRAINT user_diet_programs_diet_program_id_fkey FOREIGN KEY (diet_program_id) REFERENCES public.diet_programs(id),
  CONSTRAINT user_diet_programs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.user_follows (
  id integer NOT NULL DEFAULT nextval('user_follows_id_seq'::regclass),
  follower_id uuid NOT NULL,
  following_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_follows_pkey PRIMARY KEY (id),
  CONSTRAINT user_follows_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES public.users(id),
  CONSTRAINT user_follows_following_id_fkey FOREIGN KEY (following_id) REFERENCES public.users(id)
);
CREATE TABLE public.user_missing_equipment (
  id integer NOT NULL DEFAULT nextval('user_missing_equipment_id_seq'::regclass),
  user_id uuid NOT NULL,
  equipment_id integer NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_missing_equipment_pkey PRIMARY KEY (id),
  CONSTRAINT user_missing_equipment_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipment(id),
  CONSTRAINT user_missing_equipment_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.users (
  id uuid NOT NULL,
  full_name text NOT NULL,
  username text NOT NULL UNIQUE,
  email text NOT NULL UNIQUE,
  phone text,
  password_hash text,
  profile_picture text,
  cover_picture text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id)
);