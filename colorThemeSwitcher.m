%% MATLAB Color Theme Switcher
% ----------------------------------------------------------
% Applies custom color themes (e.g., Dracula, Monokai, Solarized, Catppuccin)
% to MATLAB using the official Settings API.
%
% Why the Settings API instead of editing matlab.mlsettings directly?
%   MATLAB keeps all of its settings in memory while it is running, and it
%   writes them back to matlab.mlsettings on shutdown. So if you overwrite the
%   .mlsettings file on disk while MATLAB is open (as the old version of this
%   script did), MATLAB clobbers your changes with its in-memory copy when it
%   exits — and the theme "reverts" to the previous one after a restart.
%
%   Writing through settings().PersonalValue instead makes MATLAB itself own
%   the new values: they take effect immediately, MATLAB persists them on exit,
%   and they are NOT reverted. This works even with MATLAB open.
% ----------------------------------------------------------
% Usage:
%   1. Set the desired theme name below
%   2. Run this script (MATLAB can stay open)
%   3. Restart MATLAB to fully redraw the desktop with the new theme
% ----------------------------------------------------------

%% 🧑‍💻 User Input
clc;

themeName = 'dracula';  % <--- 'dracula' | 'monokai' | 'solarized' | 'catppuccin'


%% Build the theme definition
[desktopStruct, syntaxStruct] = getTheme(themeName);

% The DesktopColors and SyntaxHighlightingColors settings store their value as
% a JSON-encoded string, so encode the structs once here.
desktopValue = jsonencode(desktopStruct);
syntaxValue  = jsonencode(syntaxStruct);


%% Apply through the Settings API (persists, does not get reverted)
fprintf("🎨 Applying theme '%s' via the Settings API...\n", themeName);

s = settings;

okDesktop = applyColorSetting(s.matlab.colors, 'DesktopColors', desktopValue);
okSyntax  = applyColorSetting(s.matlab.colors, 'SyntaxHighlightingColors', syntaxValue);

if okDesktop && okSyntax
    fprintf("✅ Theme '%s' applied and saved. It will persist across restarts.\n", themeName);
    fprintf("🔁 Restart MATLAB to fully redraw the desktop with the new theme.\n");
else
    warning(['Could not apply one or more colors through the Settings API. ' ...
             'Generating a themed matlab.mlsettings file as a fallback — ' ...
             'see the printed instructions.']);
    applyThemeViaFile(themeName, desktopStruct, syntaxStruct);
end


%% ----------------------------------------------------------------------------
%% Local helper functions
%% ----------------------------------------------------------------------------

function ok = applyColorSetting(group, name, jsonValue)
%APPLYCOLORSETTING Set a color setting's PersonalValue and verify it stuck.
    ok = true;
    try
        group.(name).PersonalValue = jsonValue;

        % Verify the active value matches what we wrote.
        if isequal(group.(name).ActiveValue, jsonValue)
            fprintf("  ✔ Set %s\n", name);
        else
            warning("Value for %s did not match after writing.", name);
            ok = false;
        end
    catch ME
        warning("Could not set %s via Settings API: %s", name, ME.message);
        ok = false;
    end
end


function applyThemeViaFile(themeName, desktopStruct, syntaxStruct)
%APPLYTHEMEVIAFILE Fallback: build a themed matlab.mlsettings in the current
% folder. IMPORTANT: this file must be copied into prefdir while MATLAB is
% CLOSED, otherwise MATLAB will overwrite it on exit (the very bug this script
% avoids by using the Settings API above).

    % Value as stored inside the JSON settings file (string-of-a-string).
    escapeForMLSettings = @(strct) jsonencode(jsonencode(strct));
    desktopEncoded = escapeForMLSettings(desktopStruct);
    syntaxEncoded  = escapeForMLSettings(syntaxStruct);

    % 1. Copy + unzip the current matlab.mlsettings into a working folder.
    srcFile = fullfile(prefdir, 'matlab.mlsettings');
    assert(isfile(srcFile), '❌ Cannot find matlab.mlsettings in %s', prefdir);

    dstFile = fullfile(pwd, 'matlab.mlsettings');
    copyfile(srcFile, dstFile, 'f');

    tmpDir = fullfile(pwd, 'mlsettings_tmp');
    if isfolder(tmpDir)
        rmdir(tmpDir, 's');
    end
    mkdir(tmpDir);
    unzip(dstFile, tmpDir);

    % 2. Patch the colors settings.json.
    jsonPath = fullfile(tmpDir, 'fsroot', 'settingstree', 'matlab', 'colors', 'settings.json');
    assert(isfile(jsonPath), '❌ Expected settings.json not found at: %s', jsonPath);

    jsonStruct = jsondecode(fileread(jsonPath));
    for i = 1:numel(jsonStruct.settings)
        switch jsonStruct.settings(i).name
            case 'DesktopColors'
                jsonStruct.settings(i).value = desktopEncoded;
                jsonStruct.settings(i).isUserDefined = true;
            case 'SyntaxHighlightingColors'
                jsonStruct.settings(i).value = syntaxEncoded;
                jsonStruct.settings(i).isUserDefined = true;
        end
    end

    fid = fopen(jsonPath, 'w');
    jsonStr = strrep(jsonencode(jsonStruct), '/', '\/');
    fwrite(fid, jsonStr);
    fclose(fid);

    % 3. Repackage into matlab.mlsettings in the current folder.
    zipFile        = fullfile(pwd, 'temp_theme.zip');
    mlsettingsFile = fullfile(pwd, 'matlab.mlsettings');
    if isfile(zipFile),        delete(zipFile);        end
    if isfile(mlsettingsFile), delete(mlsettingsFile); end

    allFiles = dir(fullfile(tmpDir, '**', '*'));
    allFiles = allFiles(~[allFiles.isdir]);
    relPaths = strings(numel(allFiles), 1);
    for i = 1:numel(allFiles)
        absPath = fullfile(allFiles(i).folder, allFiles(i).name);
        relPaths(i) = strrep(absPath, [tmpDir filesep], '');
    end

    oldDir = pwd;
    cd(tmpDir);
    zip(zipFile, relPaths);
    cd(oldDir);
    movefile(zipFile, mlsettingsFile);

    fprintf("📦 Themed file written to: %s\n", mlsettingsFile);
    fprintf("⚠️  To use it WITHOUT it being reverted:\n");
    fprintf("    1. Fully CLOSE MATLAB.\n");
    fprintf("    2. Copy the file above over:\n          %s\n", srcFile);
    fprintf("    3. Reopen MATLAB.\n");
end
