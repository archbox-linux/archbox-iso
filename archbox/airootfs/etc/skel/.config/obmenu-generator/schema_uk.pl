#!/usr/bin/perl

# obmenu-generator - schema file

=for comment

    item:      add an item inside the menu               {item => ["command", "label", "icon"]},
    cat:       add a category inside the menu             {cat => ["name", "label", "icon"]},
    sep:       horizontal line separator                  {sep => undef}, {sep => "label"},
    pipe:      a pipe menu entry                         {pipe => ["command", "label", "icon"]},
    raw:       any valid Openbox XML string               {raw => q(xml string)},
    begin_cat: begin of a category                  {begin_cat => ["name", "icon"]},
    end_cat:   end of a category                      {end_cat => undef},
    obgenmenu: generic menu settings                {obgenmenu => ["label", "icon"]},
    exit:      default "Exit" action                     {exit => ["label", "icon"]},

=cut

# NOTE:
#    * Keys and values are case sensitive. Keep all keys lowercase.
#    * ICON can be a either a direct path to an icon or a valid icon name
#    * Category names are case insensitive. (X-XFCE and x_xfce are equivalent)

require "$ENV{HOME}/.config/obmenu-generator/config.pl";

## Text editor
my $editor = $CONFIG->{editor};
my $terminal = $CONFIG->{terminal};

our $SCHEMA = [

    #          COMMAND                 LABEL                ICON
    {item => ["$terminal --columns=130 --rows=45 -e sudo /opt/archbox/install.sh", 'Встановити Archbox', 'system-run']},
    {item => ['pcmanfm',        'Файловий менеджер',      'folder']},
    {item => ["$terminal",             'Термінал',          'terminal-tango']},
    {item => ['firefox',  'Firefox',       'firefox']},
    {item => ['chromium',  'Chromium',       'chromium']},
    {item => ['gmrun',             'Запустити...',       'system-run']},
    #{item => ['mount /mnt/sheibe', 'Підключити sheibe',   'yellow-network']},
    #{item => ['umount /mnt/sheibe', 'Відключити sheibe',  'grey-network']},

    {sep => 'Категорії'},

    #          NAME            LABEL                ICON
    {cat => ['utility',     'Утіліти', 'applications-utilities']},
    #{cat => ['development', 'Розробка', 'applications-development']},
    {cat => ['education',   'Навчання',   'applications-science']},
    {cat => ['game',        'Ігри',       'applications-games']},
    {cat => ['graphics',    'Графіка',    'applications-graphics']},
    {cat => ['audiovideo',  'Мультимедія',  'applications-multimedia']},
    {cat => ['network',     'Мережа',     'applications-internet']},
    {cat => ['office',      'Офіс',      'applications-office']},
    {cat => ['other',       'Інше',       'applications-other']},
    {cat => ['settings',    'Налаштування',    'applications-accessories']},
    {cat => ['system',      'Система',      'applications-system']},

    #{cat => ['qt',          'QT Applications',    'qt4logo']},
    #{cat => ['gtk',         'GTK Applications',   'gnome-applications']},
    #{cat => ['x_xfce',      'XFCE Applications',  'applications-other']},
    #{cat => ['gnome',       'GNOME Applications', 'gnome-applications']},
    #{cat => ['consoleonly', 'CLI Applications',   'applications-utilities']},

    #                  LABEL          ICON
    #{begin_cat => ['My category',  'cat-icon']},
    #             ... some items ...
    #{end_cat   => undef},

    #            COMMAND     LABEL        ICON
    #{pipe => ['obbrowser', 'Disk', 'drive-harddisk']},

    ## Generic advanced settings
    #{sep       => undef},
    #{obgenmenu => ['Openbox Settings', 'openbox']},
    #{sep       => undef},

    ## Custom advanced settings
    {sep => undef},
    {begin_cat => ['Розширені налаштування', 'gnome-settings']},

        # Configuration files
        {item => ["$editor ~/.conkyrc",              'Conky RC',    'text-x-source']},
        {item => ["$editor ~/.config/tint2/tint2rc", 'Tint2 Panel', 'text-x-source']},

        # obmenu-generator category
        {begin_cat => ['Obmenu-Generator', 'menu-editor']},
            {item => ["$editor ~/.config/obmenu-generator/schema.pl", 'Menu Schema', 'text-x-source']},
            {item => ["$editor ~/.config/obmenu-generator/config.pl", 'Menu Config', 'text-x-source']},

            {sep  => undef},
            {item => ['obmenu-generator -p',       'Generate a pipe menu',              'menu-editor']},
            {item => ['obmenu-generator -s -c',    'Generate a static menu',            'menu-editor']},
            {item => ['obmenu-generator -p -i',    'Generate a pipe menu with icons',   'menu-editor']},
            {item => ['obmenu-generator -s -i -c', 'Generate a static menu with icons', 'menu-editor']},
            {sep  => undef},

            {item => ['obmenu-generator -d', 'Refresh Icon Set', 'gtk-refresh']},
        {end_cat => undef},

        # Openbox category
        {begin_cat => ['Openbox', 'openbox']},
            {item => ['openbox --reconfigure',               'Reconfigure Openbox', 'openbox']},
            {item => ["$editor ~/.config/openbox/autostart", 'Openbox Autostart',   'shellscript']},
            {item => ["$editor ~/.config/openbox/rc.xml",    'Openbox RC',          'text-xml']},
            {item => ["$editor ~/.config/openbox/menu.xml",  'Openbox Menu',        'text-xml']},
            {item => ['obmenu',  'Openbox Menu Редактор', 'openbox']},
        {end_cat => undef},

	{item => ['plank --preferences',   'Налаштування Plank',    'plank']},
    {item => ['nitrogen',              'Налаштування обкладинки',    'nitrogen']},

    {end_cat => undef},
    {sep => undef},

    ## The xscreensaver lock command
    {item => ['/home/bin/lock', 'Lock', 'lock']},

    # This option uses the default Openbox's action "Exit"
    #{exit => ['Exit', 'exit']},

    # This uses the 'oblogout' menu
    {item => ['oblogout', 'Вихід', 'exit']},
]
