UPDATE users SET password = '$2y$10$00v57Cyj5yn9ZflNXcIO3ub0PW3CJVOdfYpEHI1QL7Z.8N7FtfnjG' WHERE id = 1;
UPDATE users SET password = '$2y$10$1Qua6LaTRdmgXbP47cmyCO5zZkLAGTPNW/X5oDBoPTZh5mxKGz3Yy' WHERE id = 2;
UPDATE users SET password = '$2y$10$oEVC1hrRdDOU5zttNxfF0u27LJvl9CwuxelWoXuIYv7t4tjbRMTvm' WHERE id = 3;
UPDATE users SET password = '$2y$10$iDV8BaXMH.4p9BuiToFYe.KbQkSyZdtPa7SzQkEJDg5yS0HO7GP3C' WHERE id = 4;
SELECT id, name, role, username, password FROM users LIMIT 5;
