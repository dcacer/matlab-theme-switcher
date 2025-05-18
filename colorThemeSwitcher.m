%% MATLAB Color Theme Switcher
% ----------------------------------------------------------
% This script allows you to apply custom color themes (e.g., Dracula, Monokai)
% by modifying your `matlab.mlsettings` file. It:
%   1. Copies and unzips your current settings
%   2. Patches theme colors (Desktop + Syntax Highlighting)
%   3. Repackages and installs the new theme
% ----------------------------------------------------------
% Usage:
%   - Set the desired theme name in the input section below
%   - Run the entire script
%   - Restart MATLAB to see the effect

%% 🧑‍💻 User Input
clc;

themeName = 'catppuccin';  % <--- Change this to switch themes ('dracula', 'monokai', 'solarized', 'catppuccin')


%% STEP 1: Copy + unzip matlab.mlsettings to working folder
clc;

% 1. Locate the original mlsettings file from prefdir
srcFile = fullfile(prefdir, 'matlab.mlsettings');
assert(isfile(srcFile), ...
    '❌ Cannot find matlab.mlsettings in %s', prefdir);

fprintf("📍 Found source: %s\n", srcFile);

% 2. Copy to working directory
dstFile = fullfile(pwd, 'matlab.mlsettings');

% If already exists, back it up
if isfile(dstFile)
    copyfile(dstFile, dstFile + ".bak", 'f');
    fprintf("🗄️  Existing matlab.mlsettings backed up → matlab.mlsettings.bak\n");
end

copyfile(srcFile, dstFile, 'f');
fprintf("✅ Copied to: %s\n", dstFile);

% 3. Unzip into ./mlsettings_tmp (delete if exists)
tmpDir = fullfile(pwd, 'mlsettings_tmp');
if isfolder(tmpDir)
    rmdir(tmpDir, 's');
end
mkdir(tmpDir);

unzip(dstFile, tmpDir);
fprintf("📂 Unzipped archive into: %s\n", tmpDir);

fprintf("\n✔️ Step 1 complete — you can now parse JSON files from mlsettings_tmp\n");

%% STEP 2: Parse relevant settings.json files using helper function
fprintf('\n🔍 Parsing color settings files...\n');

% Define the file paths relative to the unzipped folder
jsonPaths = {
    fullfile(tmpDir, 'fsroot', 'settingstree', 'matlab', 'colors', 'settings.json')
};

allSettings = table();                  % combined table view
parsedData = containers.Map();         % key: filepath → value: full struct

for i = 1:numel(jsonPaths)
    jsonFile = jsonPaths{i};
    if isfile(jsonFile)
        parsed = parseGenericSettingsJson(jsonFile);     % table of entries
        parsed.SourceFile = repmat({jsonFile}, height(parsed), 1);  % add file info
        allSettings = [allSettings; parsed];              % accumulate all

        % Also store original decoded struct for later editing
        rawText = fileread(jsonFile);
        parsedStruct = jsondecode(rawText);
        parsedData(jsonFile) = parsedStruct;
    else
        warning('Missing settings file: %s', jsonFile);
    end
end


% Preview the result
fprintf('✅ Parsed %d entries from settings files.\n', height(allSettings));
disp(allSettings(1:min(10, height(allSettings)), :));  % show first few rows



%% STEP 3: Inject theme into DesktopColors and SyntaxHighlightingColors (triple-escaped)
fprintf('\n🎨 Injecting theme with exact escape formatting...\n');

[desktopStruct, syntaxStruct] = getTheme(themeName);


% Utility: triple-escaped JSON string for .mlsettings value
% escapeForMLSettings = @(s) ['"' strrep(strrep(jsonencode(s), '\', '\\'), '"', '\\"') '"'];
escapeForMLSettings = @(s) jsonencode(jsonencode(s));

% Final encoded strings
desktopEncoded = escapeForMLSettings(desktopStruct);
syntaxEncoded  = escapeForMLSettings(syntaxStruct);

% Target JSON file path
jsonPath = fullfile(tmpDir, 'fsroot', 'settingstree', 'matlab', 'colors', 'settings.json');

if ~isKey(parsedData, jsonPath)
    error('❌ Expected settings.json not found at: %s', jsonPath);
end

jsonStruct = parsedData(jsonPath);

% Apply patches in-place
for i = 1:numel(jsonStruct.settings)
    name = jsonStruct.settings(i).name;

    switch name
        case 'DesktopColors'
            jsonStruct.settings(i).value = desktopEncoded;
            jsonStruct.settings(i).isUserDefined = true;
            fprintf("✔ Patched DesktopColors\n");

        case 'SyntaxHighlightingColors'
            jsonStruct.settings(i).value = syntaxEncoded;
            jsonStruct.settings(i).isUserDefined = true;
            fprintf("✔ Patched SyntaxHighlightingColors\n");
    end
end

parsedData(jsonPath) = jsonStruct;

fprintf("✅ Theme '%s' fully injected with correct .mlsettings formatting.\n", themeName);



%% STEP 4: Write updated Dracula settings back to disk
fprintf('\n💾 Writing updated JSON files to disk...\n');

for key = keys(parsedData)
    jsonPath = key{1};                   % file path
    jsonStruct = parsedData(jsonPath);  % modified content

    try
        % Encode and write with indentation
        fid = fopen(jsonPath, 'w');
        jsonStr = jsonencode(jsonStruct);
        jsonStr = strrep(jsonStr, '/', '\/');  % fix path slashes
        fwrite(fid, jsonStr);
        fclose(fid);

        fprintf("  💾 Saved: %s\n", jsonPath);
    catch ME
        warning("❌ Failed to write %s: %s", jsonPath, ME.message);
    end
end

fprintf("✅ All modified settings written successfully.\n");


%% STEP 5: Zip and rename to matlab.mlsettings (for AppData overwrite)
fprintf('\n📦 Zipping modified settings into matlab.mlsettings...\n');

zipFile = fullfile(pwd, 'temp_theme.zip');
mlsettingsFile = fullfile(pwd, 'matlab.mlsettings');

% Clean up previous versions
if isfile(zipFile), delete(zipFile); end
if isfile(mlsettingsFile), delete(mlsettingsFile); end

% Gather all files under tmp folder
allFiles = dir(fullfile(tmpDir, '**', '*'));
allFiles = allFiles(~[allFiles.isdir]);

% Build relative paths for zip structure
relPaths = strings(numel(allFiles), 1);
for i = 1:numel(allFiles)
    absPath = fullfile(allFiles(i).folder, allFiles(i).name);
    relPaths(i) = strrep(absPath, [tmpDir filesep], '');
end

% Create zip from inside the tmp folder
oldDir = pwd;
cd(tmpDir);
zip(zipFile, relPaths);
cd(oldDir);

% Rename zip to matlab.mlsettings
movefile(zipFile, mlsettingsFile);

fprintf("✅ Theme saved as: %s\n", mlsettingsFile);
% fprintf("📂 Now copy this to:\n   %s\n", fullfile(prefdir, 'matlab.mlsettings'));
% fprintf("🔁 Then restart MATLAB to see Dracula theme in effect.\n");

%% STEP 6: Overwrite user's active matlab.mlsettings in prefdir
fprintf('\n🚀 Applying new theme by copying into prefdir...\n');

destPath = fullfile(prefdir, 'matlab.mlsettings');

% Backup existing settings before overwrite
if isfile(destPath)
    copyfile(destPath, destPath + ".bak", 'f');
    fprintf("🗄️  Existing prefdir version backed up as matlab.mlsettings.bak\n");
end

% Overwrite with the new themed file
copyfile(mlsettingsFile, destPath, 'f');

fprintf("✅ Theme '%s' installed to: %s\n", themeName, destPath);
fprintf("🔁 Please restart MATLAB to activate the theme.\n");
