class Article : Object {
    private string _title;
    private string _image_url;
    private List<Line> _lines;
    private bool parser_add_header = false;
    private bool parser_add_paragraph = false;

    public Article(string title, string image_url, string content) {
        _title = title;
        _image_url = image_url;
        _lines = new List<Line>();
        try {
            MarkupParser parser = { parser_start, parser_end, parser_text, null, null };
            var context = new MarkupParseContext(parser, 0, this, null);
            context.parse(content, -1);
        } catch (Error error) {
            print("%s\n", error.message);
        }
    }

    private void parser_start(MarkupParseContext context, string name, string[] attr_names, string[] attr_values) throws MarkupError {
        if (name == "h2") parser_add_header = true;
        if (name == "p") parser_add_paragraph = true;
    }

    private void parser_end(MarkupParseContext context, string name) throws MarkupError {
        parser_add_header = false;
        parser_add_paragraph = false;
    }

    private void parser_text(MarkupParseContext context, string text, size_t text_length) throws MarkupError {
        if (parser_add_header) {
            _lines.append(new Line(text, true));
            parser_add_header = false;
        }
        if (parser_add_paragraph) {
            _lines.append(new Line(text, false));
            parser_add_paragraph = false;
        }
    }

    public string title {
        get { return _title; }
    }

    public string image_url {
        get { return _image_url; }
    }

    public List<Line> lines {
        get { return _lines; }
    }
}
