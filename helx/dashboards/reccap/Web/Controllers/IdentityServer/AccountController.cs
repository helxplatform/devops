using IdentityServer4.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Renci.ReCCAP.Dashboard.Web.Common;
using Renci.ReCCAP.Dashboard.Web.Data;
using Renci.ReCCAP.Dashboard.Web.Services;
using Renci.ReCCAP.Dashboard.Web.ViewModels.IdentityServer;
using System;
using System.ComponentModel.DataAnnotations;
using System.Net;
using System.Security.Claims;
using System.Threading.Tasks;

namespace Renci.ReCCAP.Dashboard.Web.Controllers.IdentityServer
{
    [ApiVersionNeutral]
    [Route("api/account")]
    [Authorize]
    [ProducesResponseType(typeof(ProblemDetails), 500)]
    [ApiController]
    public class AccountController : ApiControllerBase
    {
        private readonly SignInManager<ApplicationUser> _signInManager;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IIdentityServerInteractionService _interactionService;
        private readonly IEmailSender _emailSender;
        private readonly ILogger _logger;

        /// <summary>
        /// Initializes a new instance of the <see cref="AccountController"/> class.
        /// </summary>
        /// <param name="interactionService">The identity server interaction service.</param>
        /// <param name="emailSender">The email sender.</param>
        /// <param name="signInManager">The sign in manager.</param>
        /// <param name="userManager">The user manager.</param>
        /// <param name="logger">The logger.</param>
        public AccountController(IIdentityServerInteractionService interactionService, IEmailSender emailSender, SignInManager<ApplicationUser> signInManager, UserManager<ApplicationUser> userManager, ILogger<AccountController> logger)
            : base(logger)
        {
            _signInManager = signInManager;
            _userManager = userManager;
            _interactionService = interactionService;
            _emailSender = emailSender;
            _logger = logger;
        }

        [HttpPost("login")]
        [AllowAnonymous]
        [ProducesResponseType(200)]
        public async Task<IActionResult> Login([FromBody, Required] LoginViewModel vm)
        {
            var test = await _signInManager.GetExternalAuthenticationSchemesAsync();

            var result = await _signInManager.PasswordSignInAsync(vm.Username, vm.Password, vm.IsPersistent, false);

            if (result.Succeeded)
            {
                return Ok();
            }
            else if (result.IsLockedOut)
            {
            }

            return BadRequest("The username/password couple is invalid.");
        }

        /// <summary>
        /// Externals the login.
        /// </summary>
        /// <param name="provider">The provider.</param>
        /// <param name="returnUrl">The return URL.</param>
        /// <returns></returns>
        [HttpGet("external-login")]
        [AllowAnonymous]
        [ProducesResponseType(200)]
        public async Task<IActionResult> ExternalLogin(string provider, string returnUrl)
        {
            var redirectUri = Url.RouteUrl("external-callback", new { returnUrl });
            var properties = _signInManager.ConfigureExternalAuthenticationProperties(provider, redirectUri);
            return Challenge(properties, provider);
        }

        /// <summary>
        /// Externals the login callback.
        /// </summary>
        /// <param name="returnUrl">The return URL.</param>
        /// <returns></returns>
        [HttpGet("external-login-callback", Name = "external-callback")]
        [AllowAnonymous]
        [ProducesResponseType(200)]
        public async Task<IActionResult> ExternalLoginCallback(string returnUrl)
        {
            var info = await _signInManager.GetExternalLoginInfoAsync();
            if (info == null)
            {
                return BadRequest();
            }

            var result = await _signInManager.ExternalLoginSignInAsync(info.LoginProvider, info.ProviderKey, false);

            if (result.Succeeded)
            {
                return Redirect(returnUrl);
            }
            else
            {
                //  Handles Renci Authentication
                var username = info.Principal.FindFirst("username")?.Value;
                var email = info.Principal.FindFirst(ClaimTypes.Email)?.Value;
                var displayName = info.Principal.FindFirst("displayName")?.Value;
                var user = new ApplicationUser(username)
                {
                    DisplayName = displayName,
                    Email = email
                };
                var res = await _userManager.CreateAsync(user);
                await _userManager.AddLoginAsync(user, info);
                return Redirect(returnUrl);
            }
        }

        [HttpGet("logout")]
        [AllowAnonymous]
        [ProducesResponseType(200)]
        public async Task<IActionResult> Logout(string logoutId)
        {
            await _signInManager.SignOutAsync();

            var logoutRequest = await _interactionService.GetLogoutContextAsync(logoutId);

            if (string.IsNullOrEmpty(logoutRequest.PostLogoutRedirectUri))
            {
                return Ok();
            }

            return Ok(new
            {
                RedirectUri = logoutRequest.PostLogoutRedirectUri,
            });
        }

        [HttpPost("register")]
        [AllowAnonymous]
        [ProducesResponseType(200)]
        public async Task<IActionResult> Register([FromBody, Required] RegisterViewModel vm)
        {
            var user = new ApplicationUser(vm.Username)
            {
                Email = vm.Email,
                DisplayName = vm.Username,
            };

            var result = await _userManager.CreateAsync(user, vm.Password);

            if (!result.Succeeded)
            {
                return BadRequest(result);
            }

            var code = WebUtility.UrlEncode(await this._userManager.GenerateEmailConfirmationTokenAsync(user));

            var callbackUrl = $"{this.Request.Scheme}://{this.Request.Host}{this.Request.PathBase}/confirm?username={user.UserName}&confirmation={code}";

            await _signInManager.SignInAsync(user, false);

            await this._emailSender.SendEmailAsync(
                "Confirm your email address",
                await this.RenderViewToStringAsync("Account", "ConfirmAccount", new Templates.Account.ConfirmAccountViewModel() { CallbackUrl = callbackUrl }),
                vm.Email
                );

            return Ok();
        }

        /// <summary>
        /// Confirms user e-mail.
        /// </summary>
        /// <param name="username">The username.</param>
        /// <param name="code">The code.</param>
        /// <returns>Returns OK if user was succefully confirmed.</returns>
        /// <response code="200">If user was successfully confirmed</response>
        /// <response code="400">If parameters are invalid</response>
        [HttpPost("confirm")]
        [AllowAnonymous]
        [ProducesResponseType(200)]
        [ProducesResponseType(400)]
        public async Task<IActionResult> Confirm([FromBody, Required] RegisterConfimrationViewModel vm)
        {
            var user = await this._userManager.FindByNameAsync(vm.Username);
            if (user == null)
            {
                return this.BadRequest();
            }

            IdentityResult result = await this._userManager.ConfirmEmailAsync(user, vm.Code);

            if (!result.Succeeded)
            {
                return this.BadRequest(result);
            }

            return this.Ok();
        }

        /// <summary>
        /// Changes the password.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns>Returns OK if password was successfully changed.</returns>
        /// <response code="200">If password was successfully changed</response>
        /// <response code="400">If model is invalid</response>
        [HttpPost("password-change")]
        [ProducesResponseType(200)]
        [ProducesResponseType(400)]
        [ProducesResponseType(401)]
        [ProducesResponseType(403)]
        public async Task<IActionResult> ChangePassword([FromBody, Required] ChangePasswordViewModel model)
        {
            if (model == null)
                throw new ArgumentNullException(nameof(model));

            var user = await this._userManager.GetUserAsync(User);
            if (user != null)
            {
                IdentityResult result = await this._userManager.ChangePasswordAsync(user, model.OldPassword, model.NewPassword);

                if (!result.Succeeded)
                {
                    return this.BadRequest(result);
                }
            }
            else
            {
                this._logger.LogWarning(4, $"User '{this.User.Identity.Name}' was not found while user logged in.");
            }

            return this.Ok();
        }

        /// <summary>
        /// Sends e-mail with instructions to recover forgotten password
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns>Returns OK if e-mail was successfully sent.</returns>
        /// <response code="200">If e-mail was successfully sent</response>
        /// <response code="400">If model is invalid</response>
        [HttpPost("password-forgot")]
        [AllowAnonymous]
        [ProducesResponseType(200)]
        [ProducesResponseType(400)]
        public virtual async Task<IActionResult> ForgotPassword([FromBody, Required] ForgotPasswordViewModel model)
        {
            if (model == null)
                throw new ArgumentNullException(nameof(model));

            if (ModelState.IsValid)
            {
                var user = await this._userManager.FindByNameAsync(model.Username);
                if (user != null && await this._userManager.IsEmailConfirmedAsync(user))
                {
                    var code = WebUtility.UrlEncode(await this._userManager.GeneratePasswordResetTokenAsync(user));

                    var callbackUrl = $"{this.Request.Scheme}://{this.Request.Host}{this.Request.PathBase}/password-reset?code={WebUtility.UrlEncode(code)}";

                    await this._emailSender.SendEmailAsync(
                        "Reset Password",
                        await this.RenderViewToStringAsync("Account", "ResetPassword", new Templates.Account.ResetPasswordViewModel() { CallbackUrl = callbackUrl }),
                        user.Email
                        );
                }
                else
                {
                    this._logger.LogInformation(3, $"User '{model.Username}' was not found.");
                }

                // Don't reveal if the user does not exist or is not confirmed
                return this.Ok();
            }

            // If we got this far, something failed, redisplay form
            return this.BadRequest(this.ModelState);
        }

        /// <summary>
        /// Resets password using code sent by e-mail
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns>Returns OK if password was successfully reset.</returns>
        /// <response code="200">If password was successfully reset</response>
        /// <response code="400">If model is invalid</response>
        [HttpPost("password-reset")]
        [AllowAnonymous]
        [ProducesResponseType(200)]
        [ProducesResponseType(400)]
        public async Task<ActionResult> ResetPassword([FromBody, Required] ResetPasswordViewModel model)
        {
            if (model == null)
                throw new ArgumentNullException(nameof(model));

            var user = await this._userManager.FindByNameAsync(model.Username);
            if (user != null)
            {
                var result = await this._userManager.ResetPasswordAsync(user, model.Code, model.Password);
                if (!result.Succeeded)
                {
                    return this.BadRequest(result);
                }
            }
            else
            {
                this._logger.LogInformation(3, $"User '{model.Username}' was not found.");
            }

            // Don't reveal if the user does not exist or is not confirmed
            return this.Ok();
        }
    }
}