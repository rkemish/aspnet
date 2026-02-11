using aspnet.Models;
using Azure.Identity;

var builder = WebApplication.CreateBuilder(args);

// Connect to Azure App Configuration if an endpoint is configured.
// In Azure, the endpoint is set via the AppConfiguration__Endpoint app setting.
// Locally, it falls back to appsettings.json values.
var appConfigEndpoint = builder.Configuration["AppConfiguration:Endpoint"];
if (!string.IsNullOrEmpty(appConfigEndpoint))
{
    builder.Configuration.AddAzureAppConfiguration(options =>
    {
        options.Connect(new Uri(appConfigEndpoint), new DefaultAzureCredential());
    });
}

// Add services to the container.
builder.Services.AddControllersWithViews();
builder.Services.Configure<ThemeSettings>(builder.Configuration.GetSection("Theme"));

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();


app.Run();
