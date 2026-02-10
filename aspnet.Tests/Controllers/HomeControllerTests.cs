using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using aspnet.Controllers;
using aspnet.Models;

namespace aspnet.Tests.Controllers;

public class HomeControllerTests
{
    private readonly HomeController _controller;

    public HomeControllerTests()
    {
        _controller = new HomeController();
    }

    [Fact]
    public void Index_ReturnsViewResult()
    {
        var result = _controller.Index();

        Assert.IsType<ViewResult>(result);
    }

    [Fact]
    public void Privacy_ReturnsViewResult()
    {
        var result = _controller.Privacy();

        Assert.IsType<ViewResult>(result);
    }

    [Fact]
    public void Error_ReturnsViewResultWithErrorViewModel()
    {
        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext()
        };

        var result = _controller.Error();

        var viewResult = Assert.IsType<ViewResult>(result);
        Assert.IsType<ErrorViewModel>(viewResult.Model);
    }
}
