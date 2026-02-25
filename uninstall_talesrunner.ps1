Set-StrictMode -Off

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# Check admin
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $currentIdentity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    [System.Windows.MessageBox]::Show("Please run this program as Administrator.", "Admin Required", "OK", "Warning")
    exit 1
}

$ProductName = "Talesrunner"
$Manufacturer = "Hof"
$ProductCode = "{59B48427-3D89-408C-9D6E-4C6913F13B0E}"

try { $InstallDir = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) } catch {}
if (-not $InstallDir -or $InstallDir -like '*\System32*' -or $InstallDir -like '*\SysWOW64*') {
    try { $InstallDir = Split-Path -Parent $MyInvocation.MyCommand.Definition } catch {}
}
if (-not $InstallDir) { $InstallDir = (Get-Location).Path }

$script:isDriveRoot = $InstallDir -match '^[A-Za-z]:\\\\?$'
$dangerPaths = @($env:SystemRoot, $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:USERPROFILE)
$isDangerous = $dangerPaths | Where-Object { $_ -and $InstallDir.TrimEnd('\') -eq $_.TrimEnd('\') }

$MsiFiles = @(
    "bdvid64.dll","boost_python27-vc143-mt-x64-1_81.dll","cabinet.dll","dbghelp.dll",
    "fmodex64.dll","GdiPlus.dll","Intro.dat","IntroMovie.dat","launcher.bmp",
    "libcrypto-3-x64.dll","msvcp140_atomic_wait.dll","msvcp140.dll","Patch.dat",
    "patch.png","patch.st","patch.xml","python27.dll","startup.png","talesrunner.exe",
    "TRInstAction.dll","TRUnIAction.dll","TRWebViewer.dll","upfile_warn.st","upfile.exe",
    "upfile.st","vcomp140.dll","vcruntime140_1.dll","vcruntime140.dll","WebView2Loader.dll",
    "wrap_oal.dll","x3_x64.xem","x3.xem","xcorona_arm64.xem","xcorona_x64.xem",
    "xcorona.xem","xldr_TalesRunner_TH_loader_x64.exe","xnina_x64.xem","xnina.xem"
)

# --- Load logo from embedded base64 ---
$logoBase64 = "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"

$logoBytes = [Convert]::FromBase64String($logoBase64)
$logoStream = New-Object System.IO.MemoryStream(,$logoBytes)
$logoBitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$logoBitmap.BeginInit()
$logoBitmap.StreamSource = $logoStream
$logoBitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
$logoBitmap.EndInit()
$logoBitmap.Freeze()

# --- Localization ---
$script:Lang = "en"
$L = @{
    en = @{
        title = "Talesrunner HoF Uninstaller"
        step = "Step {0} of 5"
        welcomeTitle = "Welcome"
        welcomeDesc = "This wizard will remove Talesrunner HoF from your computer."
        welcomeWarn = "Make sure the game is not running before continuing."
        installLoc = "Install location:"
        modeTitle = "Uninstall Mode"
        modeMsi = "MSI files only (38 installer files)"
        modeMsiDesc = "Removes only files from the original installer."
        modeAll = "All Talesrunner files (MSI + launcher downloads)"
        modeAllDesc = "Removes everything related to Talesrunner. Other files are safe."
        reviewTitle = "Review files to delete"
        uninstalling = "Uninstalling..."
        complete = "Uninstall Complete"
        next = "Next"
        back = "Back"
        cancel = "Cancel"
        close = "Close"
        uninstall = "Uninstall"
        confirmMsg = "Are you sure you want to delete these files? This cannot be undone."
        confirmTitle = "Confirm Uninstall"
        noFiles = "No Talesrunner files found."
        dangerMsg = "Install path is a system/root folder. Cannot proceed for safety."
        notFound = "Install directory not found. The game may already be uninstalled."
        willDelete = "WILL BE DELETED:"
        willKeep = "WILL NOT BE TOUCHED:"
        totalItems = "Total: {0} item(s) to delete"
        selectLang = "Select Language"
    }
    th = @{
        title = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("VGFsZXNydW5uZXIgSG9GIC0g4LiW4Lit4LiZ4LiB4Liy4Lij4LiV4Li04LiU4LiV4Lix4LmJ4LiH"))
        step = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LiC4Lix4LmJ4LiZ4LiV4Lit4LiZ4LiX4Li14LmIIHswfSDguIjguLLguIEgNQ=="))
        welcomeTitle = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4Lii4Li04LiZ4LiU4Li14LiV4LmJ4Lit4LiZ4Lij4Lix4Lia"))
        welcomeDesc = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LiV4Lix4Lin4LiK4LmI4Lin4Lii4LiZ4Li14LmJ4LiI4Liw4Lil4LiaIFRhbGVzcnVubmVyIEhvRiDguK3guK3guIHguIjguLLguIHguITguK3guKHguJ7guLTguKfguYDguJXguK3guKPguYzguILguK3guIfguITguLjguJM="))
        welcomeWarn = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LiB4Lij4Li44LiT4Liy4Lib4Li04LiU4LmA4LiB4Lih4LiB4LmI4Lit4LiZ4LiU4Liz4LmA4LiZ4Li04LiZ4LiB4Liy4Lij4LiV4LmI4Lit"))
        installLoc = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LiV4Liz4LmB4Lir4LiZ4LmI4LiH4LiX4Li14LmI4LiV4Li04LiU4LiV4Lix4LmJ4LiHOg=="))
        modeTitle = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LmC4Lir4Lih4LiU4LiW4Lit4LiZ4LiB4Liy4Lij4LiV4Li04LiU4LiV4Lix4LmJ4LiH"))
        modeMsi = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LmE4Lif4Lil4LmMIE1TSSDguYDguJfguYjguLLguJnguLHguYnguJkgKDM4IOC5hOC4n+C4peC5jCk="))
        modeMsiDesc = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4Lil4Lia4LmA4LiJ4Lie4Liy4Liw4LmE4Lif4Lil4LmM4LiI4Liy4LiBIGluc3RhbGxlciDguYDguJfguYjguLLguJnguLHguYnguJk="))
        modeAll = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LmE4Lif4Lil4LmMIFRhbGVzcnVubmVyIOC4l+C4seC5ieC4h+C4q+C4oeC4lCAoTVNJICsg4LmE4Lif4Lil4LmM4LiX4Li14LmI4LmC4Lir4Lil4LiU4LiI4Liy4LiBIGxhdW5jaGVyKQ=="))
        modeAllDesc = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4Lil4Lia4LiX4Li44LiB4Lit4Lii4LmI4Liy4LiH4LiX4Li14LmI4LmA4LiB4Li14LmI4Lii4Lin4LiB4Lix4LiaIFRhbGVzcnVubmVyIOC5hOC4n+C4peC5jOC4reC4t+C5iOC4meC4m+C4peC4reC4lOC4oOC4seC4og=="))
        reviewTitle = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LiV4Lij4Lin4LiI4Liq4Lit4Lia4LmE4Lif4Lil4LmM4LiX4Li14LmI4LiI4Liw4Lil4Lia"))
        uninstalling = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LiB4Liz4Lil4Lix4LiH4LiW4Lit4LiZ4LiB4Liy4Lij4LiV4Li04LiU4LiV4Lix4LmJ4LiHLi4u"))
        complete = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LiW4Lit4LiZ4LiB4Liy4Lij4LiV4Li04LiU4LiV4Lix4LmJ4LiH4LmA4Liq4Lij4LmH4LiI4Liq4Li04LmJ4LiZ"))
        next = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LiW4Lix4LiU4LmE4Lib"))
        back = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4Lii4LmJ4Lit4LiZ4LiB4Lil4Lix4Lia"))
        cancel = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4Lii4LiB4LmA4Lil4Li04LiB"))
        close = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4Lib4Li04LiU"))
        uninstall = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LiW4Lit4LiZ4LiB4Liy4Lij4LiV4Li04LiU4LiV4Lix4LmJ4LiH"))
        confirmMsg = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LiE4Li44LiT4LmB4LiZ4LmI4LmD4LiI4Lir4Lij4Li34Lit4LmE4Lih4LmI4Lin4LmI4Liy4LiV4LmJ4Lit4LiH4LiB4Liy4Lij4Lil4Lia4LmE4Lif4Lil4LmM4LmA4Lir4Lil4LmI4Liy4LiZ4Li14LmJPyDguIHguLLguKPguIHguKPguLDguJfguLPguJnguLXguYnguYTguKHguYjguKrguLLguKHguLLguKPguJbguKLguYnguK3guJnguIHguKXguLHguJrguYTguJTguYk="))
        confirmTitle = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4Lii4Li34LiZ4Lii4Lix4LiZ4LiB4Liy4Lij4LiW4Lit4LiZ4LiB4Liy4Lij4LiV4Li04LiU4LiV4Lix4LmJ4LiH"))
        noFiles = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LmE4Lih4LmI4Lie4Lia4LmE4Lif4Lil4LmMIFRhbGVzcnVubmVy"))
        dangerMsg = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LiV4Liz4LmB4Lir4LiZ4LmI4LiH4LiV4Li04LiU4LiV4Lix4LmJ4LiH4LmA4Lib4LmH4LiZ4LmC4Lif4Lil4LmA4LiU4Lit4Lij4LmM4Lij4Liw4Lia4LiaIOC5hOC4oeC5iOC4quC4suC4oeC4suC4o+C4luC4lOC4s+C5gOC4meC4tOC4meC4geC4suC4o+C5hOC4lOC5iQ=="))
        notFound = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LmE4Lih4LmI4Lie4Lia4LmC4Lif4Lil4LmA4LiU4Lit4Lij4LmM4LiV4Li04LiU4LiV4Lix4LmJ4LiHIOC5gOC4geC4oeC4reC4suC4iOC4luC4ueC4geC4luC4reC4meC4geC4suC4o+C4leC4tOC4lOC4leC4seC5ieC4h+C5hOC4m+C5geC4peC5ieC4pw=="))
        willDelete = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LiI4Liw4LiW4Li54LiB4Lil4LiaOg=="))
        willKeep = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LiI4Liw4LmE4Lih4LmI4LiW4Li54LiB4LmB4LiV4Liw4LiV4LmJ4Lit4LiHOg=="))
        totalItems = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LiX4Lix4LmJ4LiH4Lir4Lih4LiUOiB7MH0g4Lij4Liy4Lii4LiB4Liy4Lij4LiX4Li14LmI4LiI4Liw4Lil4Lia"))
        selectLang = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LmA4Lil4Li34Lit4LiB4Lig4Liy4Lip4Liy"))
    }
}

function Get-Text { param([string]$key); return $L[$script:Lang][$key] }

# ============================================================
# Loader Window - Logo with simple timed display
# ============================================================
if ($logoBitmap) {
    [xml]$loaderXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        Width="300" Height="300" WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize" Topmost="True">
    <Grid>
        <Image x:Name="imgLoader" Width="140" Height="140"
               HorizontalAlignment="Center" VerticalAlignment="Center" Opacity="0"/>
    </Grid>
</Window>
"@
    $loaderReader = New-Object System.Xml.XmlNodeReader $loaderXaml
    $script:loaderWin = [Windows.Markup.XamlReader]::Load($loaderReader)
    $script:loaderImg = $script:loaderWin.FindName("imgLoader")
    $script:loaderImg.Source = $logoBitmap

    # Use a timer to fade in manually then close
    $script:loaderStep = 0
    $script:loaderTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:loaderTimer.Interval = [TimeSpan]::FromMilliseconds(50)
    $script:loaderTimer.Add_Tick({
        $script:loaderStep++
        if ($script:loaderStep -le 40) {
            # Fade in over 2 seconds (40 steps x 50ms)
            $script:loaderImg.Opacity = $script:loaderStep / 40.0
        } elseif ($script:loaderStep -le 52) {
            # Hold for 600ms (12 steps x 50ms)
        } else {
            $script:loaderTimer.Stop()
            $script:loaderWin.Close()
        }
    })
    $script:loaderTimer.Start()
    $script:loaderWin.ShowDialog() | Out-Null
}

# ============================================================
# Splash / Language Selection Window
# ============================================================
[xml]$splashXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Talesrunner HoF" Height="380" Width="420"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#f8f9fa" FontFamily="Segoe UI" WindowStyle="None"
        AllowsTransparency="True" BorderThickness="0">
    <Border CornerRadius="12" Background="White" BorderBrush="#dde1e6" BorderThickness="1"
            Effect="{x:Null}">
        <Grid Margin="0">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <!-- Logo area -->
            <Border Grid.Row="0" CornerRadius="12,12,0,0" Padding="0,30,0,20">
                <Border.Background>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                        <GradientStop Color="#0078d4" Offset="0"/>
                        <GradientStop Color="#50a0e8" Offset="1"/>
                    </LinearGradientBrush>
                </Border.Background>
                <StackPanel HorizontalAlignment="Center">
                    <Image x:Name="splashLogo" Width="80" Height="80" Margin="0,0,0,14"/>
                    <TextBlock Text="Talesrunner HoF" FontSize="22" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/>
                    <TextBlock Text="Uninstaller" FontSize="13" Foreground="#d0e8ff" HorizontalAlignment="Center" Margin="0,4,0,0"/>
                </StackPanel>
            </Border>

            <!-- Language selection -->
            <StackPanel Grid.Row="1" VerticalAlignment="Center" HorizontalAlignment="Center" Margin="0,20,0,10">
                <TextBlock x:Name="splashLangLabel" Text="Select Language" FontSize="14" FontWeight="SemiBold" Foreground="#333" HorizontalAlignment="Center" Margin="0,0,0,16"/>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                    <Button x:Name="btnEn" Content="English" Width="130" Height="42" FontSize="14" Margin="8,0" Cursor="Hand" Background="#0078d4" Foreground="White" BorderThickness="0">
                        <Button.Template>
                            <ControlTemplate TargetType="Button">
                                <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="8" Padding="0">
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsMouseOver" Value="True">
                                        <Setter TargetName="bd" Property="Background" Value="#106ebe"/>
                                    </Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate>
                        </Button.Template>
                    </Button>
                    <Button x:Name="btnTh" Content="Thai" Width="130" Height="42" FontSize="14" Margin="8,0" Cursor="Hand" Background="#0078d4" Foreground="White" BorderThickness="0">
                        <Button.Template>
                            <ControlTemplate TargetType="Button">
                                <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="8" Padding="0">
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsMouseOver" Value="True">
                                        <Setter TargetName="bd" Property="Background" Value="#106ebe"/>
                                    </Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate>
                        </Button.Template>
                    </Button>
                </StackPanel>
            </StackPanel>

            <!-- Version & Credit -->
            <TextBlock Grid.Row="2" Text="v1.0.0 | by GOTJISAN" FontSize="10" Foreground="#aaa" HorizontalAlignment="Center" Margin="0,0,0,12"/>
        </Grid>
    </Border>
</Window>
"@

$splashReader = New-Object System.Xml.XmlNodeReader $splashXaml
$splashWin = [Windows.Markup.XamlReader]::Load($splashReader)

$splashLogo = $splashWin.FindName("splashLogo")
$splashLogo.Source = $logoBitmap

# Set window icon from embedded logo
$splashWin.Icon = $logoBitmap

$script:langChosen = $false
$btnEnCtrl = $splashWin.FindName("btnEn")
$btnThCtrl = $splashWin.FindName("btnTh")

# Set Thai text programmatically to avoid encoding issues
$splashLangLabel = $splashWin.FindName("splashLangLabel")
$thLangName = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4Lig4Liy4Lip4Liy4LmE4LiX4Lii"))
$splashLangLabel.Text = "Select Language / " + [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("4LmA4Lil4Li34Lit4LiB4Lig4Liy4Lip4Liy"))
$btnThCtrl.Content = $thLangName

$btnEnCtrl.Add_Click({ $script:Lang = "en"; $script:langChosen = $true; $splashWin.Close() })
$btnThCtrl.Add_Click({ $script:Lang = "th"; $script:langChosen = $true; $splashWin.Close() })

$splashWin.ShowDialog() | Out-Null
if (-not $script:langChosen) { exit 0 }

# ============================================================
# Main Wizard Window
# ============================================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Talesrunner HoF - Uninstaller" Height="520" Width="640"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#f8f9fa" FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="Button" x:Key="BtnPrimary">
            <Setter Property="MinWidth" Value="110"/>
            <Setter Property="Height" Value="38"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Margin" Value="6,0"/>
            <Setter Property="Background" Value="#0078d4"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="6" Padding="18,6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#106ebe"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Background" Value="#c0c0c0"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="Button" x:Key="BtnSecondary" BasedOn="{StaticResource BtnPrimary}">
            <Setter Property="Background" Value="#e1e5ea"/>
            <Setter Property="Foreground" Value="#333"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="6" Padding="18,6" BorderBrush="#ccc" BorderThickness="1">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#d0d4da"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="RadioButton" x:Key="OptRadio">
            <Setter Property="Foreground" Value="#222"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Margin" Value="0,8"/>
        </Style>
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Border Grid.Row="0" Padding="20,14">
            <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                    <GradientStop Color="#0078d4" Offset="0"/>
                    <GradientStop Color="#50a0e8" Offset="1"/>
                </LinearGradientBrush>
            </Border.Background>
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Image x:Name="headerLogo" Grid.Column="0" Width="36" Height="36" Margin="0,0,14,0" VerticalAlignment="Center"/>
                <StackPanel Grid.Column="1" VerticalAlignment="Center">
                    <TextBlock x:Name="txtTitle" Text="Talesrunner HoF Uninstaller" FontSize="19" FontWeight="Bold" Foreground="White"/>
                    <TextBlock x:Name="txtSubtitle" Text="Step 1 of 5" FontSize="11" Foreground="#d0e8ff" Margin="0,3,0,0"/>
                </StackPanel>
            </Grid>
        </Border>
        <Grid Grid.Row="1" Margin="28,18">
            <StackPanel x:Name="page1" Visibility="Visible">
                <TextBlock x:Name="p1Title" Text="Welcome" FontSize="17" FontWeight="SemiBold" Foreground="#1a1a1a" Margin="0,0,0,14"/>
                <TextBlock x:Name="p1Desc" TextWrapping="Wrap" FontSize="13" Foreground="#444"/>
                <TextBlock x:Name="p1Warn" TextWrapping="Wrap" FontSize="13" Foreground="#444" Margin="0,8,0,0"/>
                <Border Background="White" CornerRadius="8" Padding="16,12" Margin="0,22,0,0" BorderBrush="#dde1e6" BorderThickness="1">
                    <StackPanel>
                        <TextBlock x:Name="p1LocLabel" Text="Install location:" FontSize="12" Foreground="#777"/>
                        <TextBlock x:Name="txtInstallPath" FontSize="13" Foreground="#0078d4" FontWeight="SemiBold" Margin="0,4,0,0"/>
                    </StackPanel>
                </Border>
            </StackPanel>
            <StackPanel x:Name="page2" Visibility="Collapsed">
                <TextBlock x:Name="p2Title" Text="Uninstall Mode" FontSize="17" FontWeight="SemiBold" Foreground="#1a1a1a" Margin="0,0,0,14"/>
                <Border Background="White" CornerRadius="8" Padding="18,14" BorderBrush="#dde1e6" BorderThickness="1">
                    <StackPanel>
                        <RadioButton x:Name="radioMsi" GroupName="mode" IsChecked="True" Style="{StaticResource OptRadio}">
                            <StackPanel Margin="4,0,0,0">
                                <TextBlock x:Name="radioMsiText" FontWeight="SemiBold" Foreground="#222"/>
                                <TextBlock x:Name="radioMsiDesc" FontSize="11" Foreground="#888" Margin="0,3,0,0"/>
                            </StackPanel>
                        </RadioButton>
                        <Border Height="1" Background="#eee" Margin="0,8"/>
                        <RadioButton x:Name="radioAll" GroupName="mode" Style="{StaticResource OptRadio}">
                            <StackPanel Margin="4,0,0,0">
                                <TextBlock x:Name="radioAllText" FontWeight="SemiBold" Foreground="#222"/>
                                <TextBlock x:Name="radioAllDesc" FontSize="11" Foreground="#888" Margin="0,3,0,0"/>
                            </StackPanel>
                        </RadioButton>
                    </StackPanel>
                </Border>
            </StackPanel>
            <Grid x:Name="page3" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <TextBlock x:Name="p3Title" Grid.Row="0" FontSize="17" FontWeight="SemiBold" Foreground="#1a1a1a" Margin="0,0,0,10"/>
                <Border Grid.Row="1" Background="White" CornerRadius="8" Padding="6" BorderBrush="#dde1e6" BorderThickness="1">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <TextBlock x:Name="txtFileList" FontSize="11" FontFamily="Consolas" Foreground="#333" TextWrapping="Wrap" Padding="12"/>
                    </ScrollViewer>
                </Border>
            </Grid>
            <StackPanel x:Name="page4" Visibility="Collapsed">
                <TextBlock x:Name="txtStatus" FontSize="17" FontWeight="SemiBold" Foreground="#1a1a1a" Margin="0,0,0,14"/>
                <Border CornerRadius="6" Background="#e8e8e8" Height="24" ClipToBounds="True">
                    <ProgressBar x:Name="progressBar" Height="24" Minimum="0" Maximum="100" Value="0" Foreground="#0078d4" Background="Transparent" BorderThickness="0"/>
                </Border>
                <Border Background="White" CornerRadius="8" Padding="6" Margin="0,14,0,0" MaxHeight="230" BorderBrush="#dde1e6" BorderThickness="1">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <TextBlock x:Name="txtLog" FontSize="11" FontFamily="Consolas" Foreground="#333" TextWrapping="Wrap" Padding="12"/>
                    </ScrollViewer>
                </Border>
            </StackPanel>
        </Grid>
        <Border Grid.Row="2" Background="White" Padding="24,12" BorderBrush="#dde1e6" BorderThickness="0,1,0,0">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="btnCancel" Style="{StaticResource BtnSecondary}"/>
                <Button x:Name="btnBack" Style="{StaticResource BtnSecondary}" Visibility="Collapsed"/>
                <Button x:Name="btnNext" Style="{StaticResource BtnPrimary}"/>
            </StackPanel>
        </Border>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get all controls
$txtTitle = $window.FindName("txtTitle")
$txtSubtitle = $window.FindName("txtSubtitle")
$headerLogo = $window.FindName("headerLogo")
$txtInstallPath = $window.FindName("txtInstallPath")
$page1 = $window.FindName("page1")
$page2 = $window.FindName("page2")
$page3 = $window.FindName("page3")
$page4 = $window.FindName("page4")
$p1Title = $window.FindName("p1Title")
$p1Desc = $window.FindName("p1Desc")
$p1Warn = $window.FindName("p1Warn")
$p1LocLabel = $window.FindName("p1LocLabel")
$p2Title = $window.FindName("p2Title")
$radioMsi = $window.FindName("radioMsi")
$radioAll = $window.FindName("radioAll")
$radioMsiText = $window.FindName("radioMsiText")
$radioMsiDesc = $window.FindName("radioMsiDesc")
$radioAllText = $window.FindName("radioAllText")
$radioAllDesc = $window.FindName("radioAllDesc")
$p3Title = $window.FindName("p3Title")
$txtFileList = $window.FindName("txtFileList")
$txtStatus = $window.FindName("txtStatus")
$progressBar = $window.FindName("progressBar")
$txtLog = $window.FindName("txtLog")
$btnCancel = $window.FindName("btnCancel")
$btnBack = $window.FindName("btnBack")
$btnNext = $window.FindName("btnNext")

if ($logoBitmap) { $headerLogo.Source = $logoBitmap }
$window.Icon = $logoBitmap

$txtInstallPath.Text = $InstallDir
$currentPage = 1

# Apply language to all UI elements
function Apply-Language {
    $window.Title = Get-Text "title"
    $txtTitle.Text = Get-Text "title"
    $p1Title.Text = Get-Text "welcomeTitle"
    $p1Desc.Text = Get-Text "welcomeDesc"
    $p1Warn.Text = Get-Text "welcomeWarn"
    $p1LocLabel.Text = Get-Text "installLoc"
    $p2Title.Text = Get-Text "modeTitle"
    $radioMsiText.Text = Get-Text "modeMsi"
    $radioMsiDesc.Text = Get-Text "modeMsiDesc"
    $radioAllText.Text = Get-Text "modeAll"
    $radioAllDesc.Text = Get-Text "modeAllDesc"
    $p3Title.Text = Get-Text "reviewTitle"
    $txtStatus.Text = Get-Text "uninstalling"
    $btnCancel.Content = Get-Text "cancel"
    $btnNext.Content = Get-Text "next"
    $btnBack.Content = Get-Text "back"
}

Apply-Language

function Show-Page {
    param([int]$num)
    $script:currentPage = $num
    $page1.Visibility = if ($num -eq 1) { "Visible" } else { "Collapsed" }
    $page2.Visibility = if ($num -eq 2) { "Visible" } else { "Collapsed" }
    $page3.Visibility = if ($num -eq 3) { "Visible" } else { "Collapsed" }
    $page4.Visibility = if ($num -eq 4) { "Visible" } else { "Collapsed" }
    $txtSubtitle.Text = (Get-Text "step") -f $num
    $btnBack.Visibility = if ($num -gt 1 -and $num -lt 4) { "Visible" } else { "Collapsed" }
    $bc = [System.Windows.Media.BrushConverter]::new()
    switch ($num) {
        1 { $btnNext.Content = Get-Text "next"; $btnNext.Background = $bc.ConvertFrom("#0078d4") }
        2 { $btnNext.Content = Get-Text "next"; $btnNext.Background = $bc.ConvertFrom("#0078d4") }
        3 { $btnNext.Content = Get-Text "uninstall"; $btnNext.Background = $bc.ConvertFrom("#d13438") }
        4 { $btnNext.Content = Get-Text "close"; $btnNext.Background = $bc.ConvertFrom("#0078d4") }
    }
}

function Get-FilesToDelete {
    $files = [System.Collections.ArrayList]::new()
    $folders = [System.Collections.ArrayList]::new()
    if (-not (Test-Path $InstallDir)) { return @{ Files = $files; Folders = $folders } }
    foreach ($f in $MsiFiles) {
        $p = Join-Path $InstallDir $f
        if (Test-Path $p) { [void]$files.Add($p) }
    }
    if ($radioAll.IsChecked) {
        Get-ChildItem $InstallDir -Force -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -in $MsiFiles) { return }
            $isTR = $false
            if ($_.Name -match '(?i)(talesrunner|trgame|xldr_talesrunner)') { $isTR = $true }
            if ($_.Name -match '(?i)\.(xem|xam)$') { $isTR = $true }
            # --- โค้ดที่เพิ่ม: ป้องกันการกวาดไฟล์ .pkg หากติดตั้งที่ Root Drive ---
            if (-not $script:isDriveRoot -and $_.Name -match '(?i)\.pkg$') { $isTR = $true }
            if ($_.Name -match '(?i)(^InstallState$|^xigncode\.log$)') { $isTR = $true }
            if ($isTR) {
                if ($_.PSIsContainer) { [void]$folders.Add($_.FullName) }
                else { [void]$files.Add($_.FullName) }
            }
        }
    }
    return @{ Files = $files; Folders = $folders }
}

function Build-FileListText {
    param($result)
    $sb = [System.Text.StringBuilder]::new()
    $mode = if ($radioAll.IsChecked) { "All Talesrunner files" } else { "MSI files only" }
    [void]$sb.AppendLine("Mode: $mode")
    [void]$sb.AppendLine("Path: $InstallDir")
    [void]$sb.AppendLine("-------------------------------------")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine((Get-Text "willDelete"))
    foreach ($f in $result.Files) {
        $fname = [System.IO.Path]::GetFileName($f)
        $fsize = (Get-Item $f -ErrorAction SilentlyContinue).Length
        if ($fsize -gt 1MB) { $sizeText = "{0:N1} MB" -f ($fsize / 1MB) }
        else { $sizeText = "{0:N0} KB" -f ($fsize / 1KB) }
        [void]$sb.AppendLine(("  [FILE]   {0} - {1}" -f $fname, $sizeText))
    }
    foreach ($d in $result.Folders) {
        $dname = [System.IO.Path]::GetFileName($d)
        $dcount = (Get-ChildItem $d -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        [void]$sb.AppendLine(("  [FOLDER] {0} - {1} files" -f $dname, $dcount))
    }
    $allDel = @() + $result.Files + $result.Folders
    if (Test-Path $InstallDir) {
        $remaining = Get-ChildItem $InstallDir -Force | Where-Object { $_.FullName -notin $allDel }
        $remCount = ($remaining | Measure-Object).Count
        if ($remCount -gt 0) {
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine((Get-Text "willKeep"))
            foreach ($r in $remaining) {
                $rtag = if ($r.PSIsContainer) { "[FOLDER]" } else { "[FILE]  " }
                [void]$sb.AppendLine(("  {0} {1}" -f $rtag, $r.Name))
            }
        }
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine(((Get-Text "totalItems") -f ($result.Files.Count + $result.Folders.Count)))
    return $sb.ToString()
}

function Run-Uninstall {
    param($result)
    $total = $result.Files.Count + $result.Folders.Count + 3
    $done = 0
    $logSb = [System.Text.StringBuilder]::new()

    foreach ($f in $result.Files) {
        $fname = [System.IO.Path]::GetFileName($f)
        try {
            Remove-Item -Force $f -ErrorAction Stop
            [void]$logSb.AppendLine("Deleted: $fname")
        } catch {
            [void]$logSb.AppendLine(("FAILED: {0} - {1}" -f $fname, $_.Exception.Message))
        }
        $done++
        $txtLog.Text = $logSb.ToString()
        $progressBar.Value = [math]::Min(100, [int]($done / $total * 100))
        $progressBar.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
    }
    foreach ($d in $result.Folders) {
        $dname = [System.IO.Path]::GetFileName($d)
        try {
            $fc = (Get-ChildItem $d -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
            Remove-Item -Recurse -Force $d -ErrorAction Stop
            [void]$logSb.AppendLine(("Deleted folder: {0} - {1} files" -f $dname, $fc))
        } catch {
            [void]$logSb.AppendLine(("FAILED folder: {0} - {1}" -f $dname, $_.Exception.Message))
        }
        $done++
        $txtLog.Text = $logSb.ToString()
        $progressBar.Value = [math]::Min(100, [int]($done / $total * 100))
        $progressBar.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
    }
    [void]$logSb.AppendLine("Removing shortcuts...")
    $txtLog.Text = $logSb.ToString()
    @(
        [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "$ProductName.lnk"),
        [System.IO.Path]::Combine([Environment]::GetFolderPath("CommonDesktopDirectory"), "$ProductName.lnk"),
        [System.IO.Path]::Combine([Environment]::GetFolderPath("Programs"), "$ProductName.lnk"),
        [System.IO.Path]::Combine([Environment]::GetFolderPath("Programs"), $Manufacturer, "$ProductName.lnk"),
        [System.IO.Path]::Combine([Environment]::GetFolderPath("CommonPrograms"), "$ProductName.lnk"),
        [System.IO.Path]::Combine([Environment]::GetFolderPath("CommonPrograms"), $Manufacturer, "$ProductName.lnk")
    ) | ForEach-Object {
        if (Test-Path $_) {
            Remove-Item -Force $_
            [void]$logSb.AppendLine(("Removed shortcut: {0}" -f [System.IO.Path]::GetFileName($_)))
        }
        $scParent = Split-Path $_
        if ((Test-Path $scParent) -and (Get-ChildItem $scParent | Measure-Object).Count -eq 0) {
            Remove-Item -Force $scParent
        }
    }
    $done++
    $txtLog.Text = $logSb.ToString()
    $progressBar.Value = [math]::Min(100, [int]($done / $total * 100))
    $progressBar.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
    [void]$logSb.AppendLine("Cleaning registry...")
    @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$ProductCode",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$ProductCode",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$ProductCode"
    ) | ForEach-Object {
        if (Test-Path $_) {
            Remove-Item -Recurse -Force $_
            [void]$logSb.AppendLine("Removed: $_")
        }
    }
    $msiBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products"
    if (Test-Path $msiBase) {
        Get-ChildItem $msiBase | ForEach-Object {
            $propsPath = Join-Path $_.PSPath "InstallProperties"
            if (Test-Path $propsPath) {
                try {
                    $dn = (Get-ItemProperty $propsPath -ErrorAction SilentlyContinue).DisplayName
                    if ($dn -eq $ProductName) {
                        Remove-Item -Recurse -Force $_.PSPath
                        [void]$logSb.AppendLine("Removed MSI cache entry")
                    }
                } catch {}
            }
        }
    }
    $done++
    $txtLog.Text = $logSb.ToString()
    if ((Test-Path $InstallDir) -and (Get-ChildItem $InstallDir -Force | Measure-Object).Count -eq 0) {
        Remove-Item -Force $InstallDir
        [void]$logSb.AppendLine("Removed empty install folder")
        $pDir = Split-Path $InstallDir
        if ((Test-Path $pDir) -and (Get-ChildItem $pDir -Force | Measure-Object).Count -eq 0) {
            Remove-Item -Force $pDir
        }
    }
    $progressBar.Value = 100
    [void]$logSb.AppendLine("")
    [void]$logSb.AppendLine((Get-Text "complete"))
    $txtLog.Text = $logSb.ToString()
    $txtStatus.Text = Get-Text "complete"
    $txtStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#107c10")

    # --- เซฟไฟล์ Log ลงเครื่อง (โฟลเดอร์ Temp) ---
    try {
        $logFilePath = Join-Path $env:TEMP "Talesrunner_Uninstall.log"
        $txtLog.Text | Out-File -FilePath $logFilePath -Encoding UTF8
    } catch {}
}

$script:deleteResult = $null

$btnNext.Add_Click({
    switch ($script:currentPage) {
        1 {
            # --- เช็คว่าเกมเปิดอยู่ไหม (ป้องกัน File Lock) ---
            $runningProc = Get-Process -Name "talesrunner", "upfile" -ErrorAction SilentlyContinue
            if ($runningProc) {
                [System.Windows.MessageBox]::Show("Please close the game and launcher before uninstalling.`nกรุณาปิดเกมและ Launcher ก่อนทำการถอนการติดตั้ง", "Game is running", "OK", "Warning")
                return
            }
            if ($isDangerous) {
                [System.Windows.MessageBox]::Show((Get-Text "dangerMsg"), "Error", "OK", "Error")
                return
            }
            if (-not (Test-Path $InstallDir)) {
                [System.Windows.MessageBox]::Show((Get-Text "notFound"), "Not Found", "OK", "Warning")
                return
            }
            if ($isDriveRoot) {
                $driveWarnMsg = "Install path is a drive root ({0}). Only matching Talesrunner files will be deleted. Continue?" -f $InstallDir
                $driveAns = [System.Windows.MessageBox]::Show($driveWarnMsg, "Warning", "YesNo", "Warning")
                if ($driveAns -ne "Yes") { return }
            }
            Show-Page 2
        }
        2 {
            $script:deleteResult = Get-FilesToDelete
            $itemCount = $script:deleteResult.Files.Count + $script:deleteResult.Folders.Count
            if ($itemCount -eq 0) {
                [System.Windows.MessageBox]::Show((Get-Text "noFiles"), "Info", "OK", "Information")
                return
            }
            $txtFileList.Text = Build-FileListText $script:deleteResult
            Show-Page 3
        }
        3 {
            $answer = [System.Windows.MessageBox]::Show(
                (Get-Text "confirmMsg"), (Get-Text "confirmTitle"), "YesNo", "Warning")
            if ($answer -eq "Yes") {
                Show-Page 4
                $btnNext.IsEnabled = $false
                $btnCancel.IsEnabled = $false
                Run-Uninstall $script:deleteResult
                $btnNext.IsEnabled = $true
                $btnNext.Content = Get-Text "close"
                $btnCancel.Visibility = "Collapsed"
            }
        }
        4 { $window.Close() }
    }
})

$btnBack.Add_Click({
    switch ($script:currentPage) {
        2 { Show-Page 1 }
        3 { Show-Page 2 }
    }
})

$btnCancel.Add_Click({ $window.Close() })

Show-Page 1
$window.ShowDialog() | Out-Null
