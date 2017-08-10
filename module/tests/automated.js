/* global forge, asyncTest, ok, start */
/* jslint node: true */

module("oauth");

// In this test we call the example showAlert API method with an empty string
// In the example API method an empty string will immediately call the error callback
asyncTest("Attempt to show an alert with no text", 1, function() {
	forge.oauth.showAlert("", function () {
		ok(false, "Expected failure, got success");
		start();
	}, function () {
		ok(true, "Expected failure");
		start();
	});
});
