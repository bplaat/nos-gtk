const string API_KEY = "s3khkckng9or74lykjvhufbetd8jgtxcf265ltrh";

Soup.Session session;
Gtk.Window window;

Gtk.HeaderBar headerbar;
Gtk.Button back_button;
Gtk.StackSwitcher lists_page_switcher;

Gtk.Stack main_stack;
Gtk.Stack lists_page;

Gtk.ScrolledWindow article_page;
Gtk.Image article_page_image;
Gtk.Label article_page_title;
Gtk.Box article_page_content;

void addList(string name, string rss_url) {
    var articles = new List<Article>();

    var list_page = new Gtk.ScrolledWindow(null, null);
    list_page.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
    lists_page.add_titled(list_page, name, name);

    var listbox = new Gtk.FlowBox();
    listbox.selection_mode = Gtk.SelectionMode.NONE;
    listbox.min_children_per_line = 1;
    listbox.max_children_per_line = 6;
    listbox.row_spacing = 8;
    listbox.column_spacing = 8;

    listbox.child_activated.connect((row) => {
        var article = articles.nth_data(row.get_index());
        back_button.show();

        window.title = article.title + " - NOS";
        headerbar.title = article.title;
        headerbar.set_custom_title(null);

        var image_message = new Soup.Message("GET", article.image_url);
        session.queue_message(image_message, (sess, mess) => {
            try {
                var loader = new Gdk.PixbufLoader();
                loader.write(image_message.response_body.data);
                article_page_image.pixbuf = loader.get_pixbuf().scale_simple(504, 284, Gdk.InterpType.NEAREST);;
                loader.close();
            } catch (Error error) {
                print("%s\n", error.message);
            }
        });

        article_page_title.label = article.title;

        foreach (var child in article_page_content.get_children()) {
            article_page_content.remove(child);
        }

        foreach (var line in article.lines) {
            var label = new Gtk.Label(line.text);
            label.get_style_context().add_class(line.is_header ? "article-subheader" : "article-paragraph");
            label.set_line_wrap(true);
            label.set_xalign(0);
            article_page_content.add(label);
        }

        article_page_content.show_all();

        main_stack.set_visible_child(article_page);
    });
    list_page.add(listbox);

    var message = new Soup.Message("GET", "https://api.rss2json.com/v1/api.json?rss_url=" + rss_url + "&api_key=" + API_KEY + "&count=20");
    session.queue_message(message, (sess, mess) => {
        try {
            var parser = new Json.Parser();
            parser.load_from_data((string)message.response_body.data, -1);

            var root_object = parser.get_root().get_object();
            var items = root_object.get_array_member("items");

            foreach (var item_node in items.get_elements()) {
                var item = item_node.get_object();

                var article = new Article(
                    item.get_string_member("title"),
                    item.get_object_member("enclosure").get_string_member("link"),
                    item.get_string_member("content")
                );
                articles.append(article);

                var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 16);
                box.border_width = 8;

                var image = new Gtk.Image();
                box.add(image);

                var image_message = new Soup.Message("GET", article.image_url);
                session.queue_message(image_message, (sess, mess) => {
                    try {
                        var loader = new Gdk.PixbufLoader();
                        loader.write(image_message.response_body.data);
                        image.pixbuf = loader.get_pixbuf().scale_simple(504, 284, Gdk.InterpType.NEAREST);
                        loader.close();
                    } catch (Error error) {
                        print("%s\n", error.message);
                    }
                });

                var label = new Gtk.Label(article.title);
                label.get_style_context().add_class("article-title");
                box.add(label);

                listbox.insert(box, -1);
            }
            listbox.show_all();
        } catch (Error error) {
            print("%s\n", error.message);
        }
    });
}

int main(string[] args) {
    Gtk.init(ref args);

    try {
        var screen = Gdk.Screen.get_default();
        var provider = new Gtk.CssProvider();
        provider.load_from_file(File.new_for_path("style.css"));
        Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    } catch (Error error) {
        print("%s\n", error.message);
    }

    session = new Soup.Session();

    window = new Gtk.Window();
    window.title = "NOS";

    headerbar = new Gtk.HeaderBar();
    headerbar.title = "NOS";
    headerbar.show_close_button = true;

    window.set_titlebar(headerbar);
    window.set_default_size(1280, 720);
    window.destroy.connect(Gtk.main_quit);

    back_button = new Gtk.Button.from_icon_name("go-previous-symbolic", Gtk.IconSize.BUTTON);
    back_button.clicked.connect(() => {
        main_stack.set_visible_child(lists_page);
        back_button.hide();
        window.title = "NOS";
        headerbar.title = "NOS";
        headerbar.set_custom_title(lists_page_switcher);
    });
    headerbar.pack_start(back_button);

    main_stack = new Gtk.Stack();
    main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
    window.add(main_stack);

    lists_page = new Gtk.Stack();
    lists_page.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
    main_stack.add(lists_page);

    lists_page_switcher = new Gtk.StackSwitcher();
    lists_page_switcher.stack = lists_page;
    headerbar.set_custom_title(lists_page_switcher);

    addList("Laatste", "http://feeds.nos.nl/nosnieuwsalgemeen");
    addList("Sport", "http://feeds.nos.nl/nossportalgemeen");
    addList("Tech", "http://feeds.nos.nl/nosnieuwstech");

    article_page = new Gtk.ScrolledWindow(null, null);
    article_page.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
    main_stack.add(article_page);

    var article_page_container = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    article_page.add(article_page_container);

    article_page_image = new Gtk.Image();
    article_page_container.add(article_page_image);

    var article_page_main_container = new Gtk.Box(Gtk.Orientation.VERTICAL, 16);
    article_page_main_container.border_width = 16;
    article_page_container.add(article_page_main_container);

    article_page_title = new Gtk.Label("");
    article_page_title.get_style_context().add_class("article-header");
    article_page_title.set_line_wrap(true);
    article_page_title.set_xalign(0);
    article_page_main_container.add(article_page_title);

    article_page_content = new Gtk.Box(Gtk.Orientation.VERTICAL, 16);
    article_page_main_container.add(article_page_content);

    window.show_all();
    back_button.hide();

    Gtk.main();

    return 0;
}
