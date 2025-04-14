(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_consts;

interface

uses
Messages;

const

  CURRENT_PROJECT_VERSION = 6;

  PARAMETERS_FILE_NAME = 'params.dsc';
  PROJECT_FILE_NAME = 'project.dsc';

  MAX_RECENT_CAPACITY = 10;

  WM_RECALC = WM_USER + 1;
  WM_STARTEDITING = WM_USER + 2;

  PAlias : array [1..3] of string = ('H','s','r');


  APPDATA_DIR_NAME = 'X-RayCalc3';
  SETTINGS_FILE_NAME = 'xrc3.ini';
  APP_HELP_FILENAME = 'xraycalc3.chm';
  VERINFO_FILENAME = 'version.info';
  LICENSE_FILENAME = 'xraycalc3.lic';
  DEFAULT_PROJECT_NAME = 'NewProject.xrcx';
  PROJECT_EXT = '.xrcx';
  BACKUP_DIR_NAME = 'Backup';

implementation

end.
