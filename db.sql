-- --------------------------------------------------------
-- Hôte:                         127.0.0.1
-- Version du serveur:           11.7.2-MariaDB - mariadb.org binary distribution
-- SE du serveur:                Win64
-- HeidiSQL Version:             12.16.0.7229
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

CREATE TABLE IF NOT EXISTS `group_grades` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `rank` int(11) NOT NULL,
  `perms` text NOT NULL,
  `groupId` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `groupId` (`groupId`),
  KEY `idx_group_grades_id` (`id`),
  CONSTRAINT `group_grades_ibfk_1` FOREIGN KEY (`groupId`) REFERENCES `group_list` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `group_list` (
  `id` varchar(50) NOT NULL,
  `name` varchar(50) NOT NULL,
  `devise` text DEFAULT NULL,
  `rgb` text DEFAULT NULL,
  `is_official` int(11) DEFAULT 0,
  `slots` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_group_list_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `group_members` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) DEFAULT NULL,
  `label` varchar(50) DEFAULT NULL,
  `id_grade` int(11) NOT NULL,
  `groupId` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `id_grade` (`id_grade`),
  KEY `groupId` (`groupId`),
  KEY `idx_group_members_id` (`id`),
  CONSTRAINT `group_members_ibfk_1` FOREIGN KEY (`groupId`) REFERENCES `group_list` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `labs` (
  `id` varchar(50) NOT NULL,
  `label` text DEFAULT NULL,
  `coords` longtext DEFAULT NULL,
  `type` text NOT NULL,
  `level` int(11) NOT NULL,
  `weeds` longtext NOT NULL,
  `circuits` longtext NOT NULL,
  `trays` longtext NOT NULL,
  `start` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `territories` (
  `id` varchar(50) NOT NULL,
  `label` text NOT NULL,
  `influence` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`influence`)),
  `coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`coords`)),
  `minZ` float DEFAULT NULL,
  `maxZ` float DEFAULT NULL,
  `start` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_territories_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `statistics_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `timestamp` datetime DEFAULT current_timestamp(),
  `type` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
