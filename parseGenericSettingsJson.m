function T = parseGenericSettingsJson(jsonFilePath)
%PARSEGENERICSETTINGSJSON Parses a MATLAB settings.json file from .mlsettings
% Works with files like:
%   - colors/settings.json
%   - colors/commandwindow/settings.json
%   - colors/programmingtools/settings.json
%
% Returns a table with Name, HasValue, IsUserDefined, IsVector, Visible, Value

    fid = fopen(jsonFilePath, 'r');
    raw = fread(fid, inf, '*char')';
    fclose(fid);

    data = jsondecode(raw);
    entries = data.settings;

    names = {};
    values = {};
    visible = [];
    hasValue = [];
    isVector = [];
    isUserDefined = [];

    for i = 1:length(entries)
        setting = entries(i);

        names{end+1} = setting.name;
        visible(end+1) = getfield_safe(setting.attributes, 'visible', false);
        hasValue(end+1) = getfield_safe(setting, 'hasValue', false);
        isVector(end+1) = getfield_safe(setting, 'isVector', false);
        isUserDefined(end+1) = getfield_safe(setting, 'isUserDefined', false);

        % Attempt to decode the value
        try
            parsedVal = jsondecode(setting.value);
            if isstruct(parsedVal) && isfield(parsedVal, 'mwdata')
                values{end+1} = parsedVal.mwdata;
            else
                values{end+1} = parsedVal;
            end
        catch
            % Use raw string as fallback
            values{end+1} = setting.value;
        end
    end

    T = table(names', hasValue', isUserDefined', isVector', visible', values', ...
        'VariableNames', {'Name', 'HasValue', 'IsUserDefined', 'IsVector', 'Visible', 'Value'});
end

function val = getfield_safe(s, field, default)
%GETFIELD_SAFE Returns s.field or default if field doesn't exist
    if isfield(s, field)
        val = s.(field);
    else
        val = default;
    end
end
