public class App : Gtk.Application {
    public App() {
        Object(
            application_id: "ml.bastiaan.nos",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    const string API_KEY = "s3khkckng9or74lykjvhufbetd8jgtxcf265ltrh";

    Soup.Session session;
    Gtk.ApplicationWindow window;

    Gtk.HeaderBar headerbar;
    Gtk.Button back_button;
    Gtk.StackSwitcher lists_page_switcher;

    Gtk.Stack main_stack;
    Gtk.Stack lists_page;

    Gtk.ScrolledWindow article_page;
    Gtk.Image article_page_image;
    Gtk.Label article_page_title;
    Gtk.Box article_page_content;

    protected override void activate() {
        try {
            var screen = Gdk.Screen.get_default();
            var provider = new Gtk.CssProvider();
            provider.load_from_data("""
.article-title { font-size: 14px; font-weight: bold; }
.article-header { font-size: 24px; font-weight: bold; }
.article-subheader { font-size: 18px; font-weight: bold; }
.article-paragraph { font-size: 16px; }
""", -1);
            Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error error) {
            print("%s\n", error.message);
        }

        session = new Soup.Session();

        window = new Gtk.ApplicationWindow(this);
        window.icon_name = "applications-internet";
        window.default_width = 1280;
        window.default_height = 720;

        headerbar = new Gtk.HeaderBar();
        headerbar.title = "NOS";
        headerbar.show_close_button = true;
        window.set_titlebar(headerbar);

        back_button = new Gtk.Button.from_icon_name("go-previous-symbolic", Gtk.IconSize.BUTTON);
        back_button.clicked.connect(() => {
            main_stack.set_visible_child(lists_page);
            back_button.hide();
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
        addList("Binnenland", "http://feeds.nos.nl/nosnieuwsbinnenland");
        addList("Buitenland", "http://feeds.nos.nl/nosnieuwsbuitenland");
        addList("Economie", "http://feeds.nos.nl/nosnieuwseconomie");
        addList("Tech", "http://feeds.nos.nl/nosnieuwstech");
        addList("Sport", "http://feeds.nos.nl/nossportalgemeen");

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
    }

    void loadImage(Gtk.Image image, string image_url, int width, int height) {
        var message = new Soup.Message("GET", image_url);
        session.queue_message(message, (sess, mess) => {
            try {
                var image_loader = new Gdk.PixbufLoader();
                image_loader.write(message.response_body.data);
                image.pixbuf = image_loader.get_pixbuf().scale_simple(width, height, Gdk.InterpType.NEAREST);
                image_loader.close();
            } catch (Error error) {
                print("%s\n", error.message);
            }
        });
    }

    void addList(string name, string rss_url) {
        var articles = new List<Article>();

        var list_page = new Gtk.ScrolledWindow(null, null);
        list_page.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        lists_page.add_titled(list_page, name, name);

        var flowbox = new Gtk.FlowBox();
        flowbox.selection_mode = Gtk.SelectionMode.NONE;
        flowbox.min_children_per_line = 1;
        flowbox.max_children_per_line = 6;
        flowbox.row_spacing = 8;
        flowbox.column_spacing = 8;

        flowbox.child_activated.connect((row) => {
            var article = articles.nth_data(row.get_index());
            back_button.show();

            headerbar.title = article.title;
            headerbar.set_custom_title(null);

            loadImage(article_page_image, article.image_url, 504, 284);

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
        list_page.add(flowbox);

        var message = new Soup.Message("GET", "https://api.rss2json.com/v1/api.json?rss_url=" + Soup.URI.encode(rss_url, null) + "&api_key=" + API_KEY + "&count=20");
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
                    loadImage(image, article.image_url, 504, 284);
                    box.add(image);

                    var label = new Gtk.Label(article.title);
                    label.get_style_context().add_class("article-title");
                    box.add(label);

                    flowbox.add(box);
                }
                flowbox.show_all();
            } catch (Error error) {
                print("%s\n", error.message);
            }
        });
    }

    public static int main(string[] args) {
        var app = new App();
        return app.run(args);
    }
}
