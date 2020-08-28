﻿using System;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Renci.ReCCAP.Dashboard.Web.Common.Converters
{
    public class GuidUrlConverter : JsonConverter<Guid>
    {
        public override Guid Read(
            ref Utf8JsonReader reader,
            Type typeToConvert,
            JsonSerializerOptions options) =>
                reader.GetString().DecodeFromUrlCode();

        public override void Write(
            Utf8JsonWriter writer,
            Guid guidValue,
            JsonSerializerOptions options) =>
                writer.WriteStringValue(guidValue.EncodeToUrlCode());
    }
}