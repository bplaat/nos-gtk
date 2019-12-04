class Line : Object {
    private string _text;
    private bool _is_header;

    public Line(string text, bool is_header) {
        _text = text;
        _is_header = is_header;
    }

    public string text {
        get { return _text; }
    }

    public bool is_header {
        get { return _is_header; }
    }
}
