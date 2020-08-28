using System;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace Renci.ReCCAP.Dashboard.Web.Common
{
    public static class StringExtenstions
    {
        /// <summary>
        /// white space, em-dash, en-dash, underscore
        /// </summary>
        private static readonly Regex WordDelimiters = new Regex(@"[\s—–_]", RegexOptions.Compiled);

        /// <summary>
        /// Characters that are not valid
        /// </summary>
        private static readonly Regex InvalidChars = new Regex(@"[^a-z0-9\-]", RegexOptions.Compiled);

        /// <summary>
        /// The multiple hyphens
        /// </summary>
        private static readonly Regex MultipleHyphens = new Regex(@"-{2,}", RegexOptions.Compiled);

        /// <summary>
        /// Generates URL slug.
        /// </summary>
        /// <param name="value">The value.</param>
        /// <returns></returns>
        public static string ToUrlSlug(this string value)
        {
            if (value == null)
                throw new ArgumentNullException(nameof(value));

            // convert to lower case
            value = value.ToLowerInvariant();

            // remove diacritics (accents)
            value = RemoveDiacritics(value);

            // ensure all word delimiters are hyphens
            value = WordDelimiters.Replace(value, "-");

            // strip out invalid characters
            value = InvalidChars.Replace(value, "");

            // replace multiple hyphens (-) with a single hyphen
            value = MultipleHyphens.Replace(value, "-");

            // trim hyphens (-) from ends
            return value.Trim('-');
        }

        /// <summary>
        /// Encodes the specified unique identifier as URL code.
        /// </summary>
        /// <param name="guid">The unique identifier.</param>
        /// <returns></returns>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Design", "CA1055:Uri return values should not be strings", Justification = "<Pending>")]
        public static string EncodeToUrlCode(this Guid guid)
        {
            string enc = Convert.ToBase64String(guid.ToByteArray());
            enc = enc.Replace("/", "_", StringComparison.InvariantCultureIgnoreCase);
            enc = enc.Replace("+", "-", StringComparison.InvariantCultureIgnoreCase);
            return $"_{enc.Substring(0, 22)}";
        }

        /// <summary>
        /// Decodes the specified string from URL code.
        /// </summary>
        /// <param name="encoded">The encoded.</param>
        /// <returns></returns>
        public static Guid DecodeFromUrlCode(this string encoded)
        {
            if (string.IsNullOrEmpty(encoded))
            {
                return Guid.Empty;
            }
            encoded = encoded.Substring(1, 22);
            encoded = encoded.Replace("_", "/", StringComparison.InvariantCultureIgnoreCase);
            encoded = encoded.Replace("-", "+", StringComparison.InvariantCultureIgnoreCase);
            byte[] buffer = Convert.FromBase64String(encoded + "==");
            return new Guid(buffer);
        }

        private static string RemoveDiacritics(string text)
        {
            string normilizedText = text.Normalize(NormalizationForm.FormD);
            StringBuilder sb = new StringBuilder();

            for (int ich = 0; ich < normilizedText.Length; ich++)
            {
                UnicodeCategory uc = CharUnicodeInfo.GetUnicodeCategory(normilizedText[ich]);
                if (uc != UnicodeCategory.NonSpacingMark)
                {
                    sb.Append(normilizedText[ich]);
                }
            }

            return (sb.ToString().Normalize(NormalizationForm.FormC));
        }
    }
}