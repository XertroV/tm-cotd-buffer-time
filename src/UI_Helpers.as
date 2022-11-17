UI::Font@ headingFont = UI::LoadFont("DroidSans.ttf", 22, -1, -1, false, true);
UI::Font@ subHeadingFont = UI::LoadFont("DroidSans.ttf", 19, -1, -1, false, true);

void Heading(const string &in text) {
    UI::PushFont(headingFont);
    UI::Text(text);
    UI::PopFont();
}

void SubHeading(const string &in text) {
    UI::PushFont(subHeadingFont);
    UI::Text(text);
    UI::PopFont();
}
