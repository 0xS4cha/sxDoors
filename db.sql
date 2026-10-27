-- sxDoors
-- This table is created automatically on the first start when oxmysql is used.
-- Importing this file is only needed if your database user cannot create tables.

CREATE TABLE IF NOT EXISTS `sx_doors` (
  `id` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `data` longtext NOT NULL,
  `locked` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
