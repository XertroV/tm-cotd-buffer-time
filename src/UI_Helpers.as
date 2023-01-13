UI::Font@ headingFont = UI::LoadFont("DroidSans.ttf", 26);
UI::Font@ subHeadingFont = UI::LoadFont("DroidSans.ttf", 20);

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
