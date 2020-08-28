using System;

namespace Renci.ReCCAP.Dashboard.Web.Common.Attributes
{
    [AttributeUsage(AttributeTargets.Property, Inherited = true, AllowMultiple = false)]
    public class SortPropertyNameAttribute : Attribute
    {
        public string Name { get; }

        public SortPropertyNameAttribute(string name)
        {
            this.Name = name;
        }
    }
}