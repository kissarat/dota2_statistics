/*
Navicat MySQL Data Transfer

Source Server         : dota2
Source Server Version : 50614
Source Host           : localhost:3306
Source Database       : dota2

Target Server Type    : MYSQL
Target Server Version : 50614
File Encoding         : 65001

Date: 2013-10-24 22:30:29
*/

SET FOREIGN_KEY_CHECKS=0;
-- ----------------------------
-- Table structure for `entid`
-- ----------------------------
DROP TABLE IF EXISTS `entid`;
CREATE TABLE `entid` (
  `id` int(4) NOT NULL,
  `name` varchar(32) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of entid
-- ----------------------------
INSERT INTO `entid` VALUES ('1471', 'npc_good_rax_range_bot');
INSERT INTO `entid` VALUES ('1472', 'npc_good_rax_melee_bot');
INSERT INTO `entid` VALUES ('1477', 'npc_dota_goodguys_tower4_bot');
INSERT INTO `entid` VALUES ('1479', 'npc_good_rax_melee_mid');
INSERT INTO `entid` VALUES ('1480', 'npc_dota_goodguys_tower3_mid');
INSERT INTO `entid` VALUES ('1481', 'npc_good_rax_range_mid');
INSERT INTO `entid` VALUES ('1485', 'npc_dota_goodguys_tower4_top');
INSERT INTO `entid` VALUES ('1492', 'npc_good_rax_melee_top');
INSERT INTO `entid` VALUES ('1493', 'npc_good_rax_range_top');
INSERT INTO `entid` VALUES ('1494', 'npc_dota_goodguys_tower3_top');
INSERT INTO `entid` VALUES ('1495', 'npc_npc_dota_goodguys_tower1_top');
INSERT INTO `entid` VALUES ('1496', 'npc_dota_goodguys_tower2_top');
INSERT INTO `entid` VALUES ('1497', 'npc_dota_goodguys_tower1_mid');
INSERT INTO `entid` VALUES ('1498', 'npc_dota_goodguys_tower2_mid');
INSERT INTO `entid` VALUES ('1499', 'npc_dota_goodguys_tower2_bot');
INSERT INTO `entid` VALUES ('1500', 'npc_dota_goodguys_tower1_bot');
INSERT INTO `entid` VALUES ('1502', 'npc_dota_goodguys_fort');
INSERT INTO `entid` VALUES ('1507', 'npc_bad_rax_range_mid');
INSERT INTO `entid` VALUES ('1508', 'npc_bad_rax_melee_mid');
INSERT INTO `entid` VALUES ('1514', 'npc_bad_rax_range_bot');
INSERT INTO `entid` VALUES ('1515', 'npc_bad_rax_melee_bot');
INSERT INTO `entid` VALUES ('1516', 'npc_dota_badguys_tower3_bot');
INSERT INTO `entid` VALUES ('1519', 'npc_dota_badguys_tower4_bot');
INSERT INTO `entid` VALUES ('1520', 'npc_dota_badguys_tower4_top');
INSERT INTO `entid` VALUES ('1526', 'npc_bad_rax_range_top');
INSERT INTO `entid` VALUES ('1527', 'npc_bad_rax_melee_top');
INSERT INTO `entid` VALUES ('1528', 'npc_dota_badguys_tower3_top');
INSERT INTO `entid` VALUES ('1529', 'npc_dota_badguys_tower1_top');
INSERT INTO `entid` VALUES ('1530', 'npc_dota_badguys_tower2_top');
INSERT INTO `entid` VALUES ('1531', 'npc_dota_badguys_tower2_mid');
INSERT INTO `entid` VALUES ('1532', 'npc_dota_badguys_tower1_mid');
INSERT INTO `entid` VALUES ('1533', 'npc_dota_badguys_tower1_bot');
INSERT INTO `entid` VALUES ('1534', 'npc_dota_badguys_tower2_bot');
INSERT INTO `entid` VALUES ('1537', 'npc_dota_badguys_tower3_mid');
INSERT INTO `entid` VALUES ('1539', 'npc_dota_badguys_fort');

-- ----------------------------
-- Table structure for `event`
-- ----------------------------
DROP TABLE IF EXISTS `event`;
CREATE TABLE `event` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `time` datetime DEFAULT CURRENT_TIMESTAMP,
  `match_id` int(11) NOT NULL,
  `name` varchar(32) NOT NULL,
  `message` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of event
-- ----------------------------

-- ----------------------------
-- Table structure for `match`
-- ----------------------------
DROP TABLE IF EXISTS `match`;
CREATE TABLE `match` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `start` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of match
-- ----------------------------

-- ----------------------------
-- Table structure for `match_user`
-- ----------------------------
DROP TABLE IF EXISTS `match_user`;
CREATE TABLE `match_user` (
  `match_id` int(11) NOT NULL,
  `steam_id` varchar(22) NOT NULL,
  `user_name` varchar(32) DEFAULT NULL,
  `index` int(2) DEFAULT NULL,
  `team` int(1) NOT NULL,
  `connected` datetime DEFAULT NULL,
  `level` int(2) NOT NULL DEFAULT '1',
  `death` int(3) NOT NULL DEFAULT '0',
  `assist` int(3) NOT NULL DEFAULT '0',
  `kill` int(2) NOT NULL DEFAULT '0',
  `gold` int(11) NOT NULL DEFAULT '0',
  `xp` int(11) NOT NULL DEFAULT '0',
  UNIQUE KEY `unique_steam_id` (`match_id`,`steam_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of match_user
-- ----------------------------
