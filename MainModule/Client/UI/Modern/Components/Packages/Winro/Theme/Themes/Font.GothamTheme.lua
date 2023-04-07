local Offset = 0
local HeightOffset = Offset
local Styles = {
    ['fonts/Caption'] = {
        Font = Font.fromEnum(Enum.Font.Gotham),
        Size = 12 + Offset,
        LineHeight = 16 + HeightOffset,
        ParagraphSpacing = 0,
        LetterSpacing = 0.0,
    },
    ['fonts/Body'] = {
        Font = Font.fromEnum(Enum.Font.Gotham),
        Size = 14 + Offset,
        LineHeight = 20 + HeightOffset,
        ParagraphSpacing = 0,
        LetterSpacing = 0.0,
    },
    ['fonts/Body_Strong'] = {
        Font = Font.fromEnum(Enum.Font.GothamMedium),
        Size = 14 + Offset,
        LineHeight = 20 + HeightOffset,
        ParagraphSpacing = 0,
        LetterSpacing = 0.0,
    },
    ['fonts/Body_Large'] = {
        Font = Font.fromEnum(Enum.Font.Gotham),
        Size = 18 + Offset,
        LineHeight = 24 + HeightOffset,
        ParagraphSpacing = 0,
        LetterSpacing = 0.0,
    },
    ['fonts/Subtitle'] = {
        Font = Font.fromEnum(Enum.Font.GothamMedium),
        Size = 20 + Offset,
        LineHeight = 28 + HeightOffset,
        ParagraphSpacing = 0,
        LetterSpacing = 0.0,
    },
    ['fonts/Title'] = {
        Font = Font.fromEnum(Enum.Font.GothamMedium),
        Size = 28 + Offset,
        LineHeight = 36 + HeightOffset,
        ParagraphSpacing = 0,
        LetterSpacing = 0.0,
    },
    ['fonts/Title_Large'] = {
        Font = Font.fromEnum(Enum.Font.GothamMedium),
        Size = 40 + Offset,
        LineHeight = 52 + HeightOffset,
        ParagraphSpacing = 0,
        LetterSpacing = 0.0,
    },
    ['fonts/Display'] = {
        Font = Font.fromEnum(Enum.Font.GothamMedium),
        Size = 68 + Offset,
        LineHeight = 92 + HeightOffset,
        ParagraphSpacing = 0,
        LetterSpacing = 0.0,
    },
    ['fonts/Icon/Small'] = {
        Font = nil,
        Size = 12 + Offset,
        LineHeight = 12 + HeightOffset,
        ParagraphSpacing = 0,
        LetterSpacing = 0.0,
    },
    ['fonts/Icon/Standard'] = {
        Font = nil,
        Size = 16 + Offset,
        LineHeight = 16 + HeightOffset,
        ParagraphSpacing = 0,
        LetterSpacing = 0.0,
    }
}

-- Format the styles
for _, Style in pairs(Styles) do
	Style.LineHeight = Style.LineHeight/Style.Size
end

return Styles