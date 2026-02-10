using aspnet.Models;

namespace aspnet.Tests.Models;

public class ErrorViewModelTests
{
    [Fact]
    public void ShowRequestId_ReturnsTrue_WhenRequestIdHasValue()
    {
        var model = new ErrorViewModel { RequestId = "abc-123" };

        Assert.True(model.ShowRequestId);
    }

    [Fact]
    public void ShowRequestId_ReturnsFalse_WhenRequestIdIsNull()
    {
        var model = new ErrorViewModel { RequestId = null };

        Assert.False(model.ShowRequestId);
    }

    [Fact]
    public void ShowRequestId_ReturnsFalse_WhenRequestIdIsEmpty()
    {
        var model = new ErrorViewModel { RequestId = string.Empty };

        Assert.False(model.ShowRequestId);
    }
}
