import streamlit as st
import pandas as pd
import plotly.express as px
import folium
from streamlit_folium import folium_static
import json
import datetime

# Load datasets
customer_df = pd.read_csv("Loan_Risk_Assessment/customerdata.csv")
loan_df = pd.read_csv("Loan_Risk_Assessment/loandata.csv")
loan_reason_df = pd.read_csv("Loan_Risk_Assessment/loanreason.csv")
loan_status_df = pd.read_csv("Loan_Risk_Assessment/loanstatus.csv")
employment_df = pd.read_csv("Loan_Risk_Assessment/employmentlength.csv")

# Merge necessary dataframes, avoiding duplicate columns
merged_df = customer_df.merge(loan_df, on='loan_id', how='inner')
merged_df = merged_df.merge(loan_reason_df.rename(columns={'reasoncode': 'reason_code'}), on='reason_code', how='left')
merged_df = merged_df.merge(employment_df, on='emp_length', how='left')
merged_df = merged_df.merge(loan_status_df, left_on='loan_status_code_y', right_on='loan_status_code', how='left')

# Drop duplicate columns if they exist
merged_df = merged_df.loc[:, ~merged_df.columns.duplicated()]

# Remove faulty employment length values over 50
merged_df = merged_df[merged_df['emp_length'] <= 50]

import datetime

# Ensure issue_date is a datetime column
merged_df['issue_date'] = pd.to_datetime(merged_df['issue_date'], errors='coerce')
merged_df = merged_df.dropna(subset=['issue_date'])

# Convert issue_date to YYYYMM integer format
merged_df['issue_month'] = merged_df['issue_date'].dt.year * 100 + merged_df['issue_date'].dt.month

# Extract min and max month values
if not merged_df.empty:
    min_month = int(merged_df['issue_month'].min())  # Ensure integer format
    max_month = int(merged_df['issue_month'].max())
else:
    min_month, max_month = 201701, 202512  # Default range

# Sidebar Filters
st.sidebar.header("Filters")

# Slider for month range (YYYYMM)
selected_months = st.sidebar.slider(
    "Select Date Range (YYYYMM)",
    min_value=min_month,
    max_value=max_month,
    value=(min_month, max_month),
    step=1
)

# Convert selected YYYYMM back to datetime
selected_start_date = datetime.datetime.strptime(str(selected_months[0]), "%Y%m")
selected_end_date = datetime.datetime.strptime(str(selected_months[1]), "%Y%m")

# Filter DataFrame based on selected date range
filtered_df = merged_df[
    (merged_df['issue_date'] >= selected_start_date) &
    (merged_df['issue_date'] <= selected_end_date)
]

# Extract min and max months
if not merged_df.empty and merged_df['issue_date'].notna().any():
    min_month = merged_df['issue_date'].min().strftime('%Y-%m')
    max_month = merged_df['issue_date'].max().strftime('%Y-%m')
else:
    min_month, max_month = "2017-01", "2025-12"  # Default range

# Sidebar Filters
st.sidebar.header("Filters")
selected_months = st.sidebar.slider("Select Date Range", min_value=min_month, max_value=max_month, value=(min_month, max_month))

loan_types = merged_df['reason'].unique()
selected_loans = st.sidebar.multiselect("Select Loan Type(s)", loan_types, default=loan_types.tolist())

# Apply filters
filtered_df = merged_df[
    (merged_df['issue_date'] >= pd.to_datetime(selected_months[0])) &
    (merged_df['issue_date'] <= pd.to_datetime(selected_months[1])) &
    (merged_df['reason'].isin(selected_loans))
]

# Loan Distribution Over Time
st.subheader("Loan Distribution Over Time")
time_series = filtered_df.groupby(filtered_df['issue_date'].dt.to_period('M')).size().reset_index()
time_series.columns = ['Month', 'Number of Loans']
time_series['Month'] = time_series['Month'].astype(str)
fig1 = px.line(time_series, x='Month', y='Number of Loans', title='Loans Issued Over Time')
st.plotly_chart(fig1)

# Loan Amount by Reason
st.subheader("Loan Amount by Loan Reason")
loan_reason_fig = px.bar(filtered_df.groupby('reason')['loan_amnt'].mean().reset_index(), x='reason', y='loan_amnt',
                         title="Average Loan Amount by Reason", labels={'loan_amnt': 'Avg Loan Amount ($)'})
st.plotly_chart(loan_reason_fig)

# Delinquency KPIs
st.subheader("Delinquency Metrics")
delinquency_counts = filtered_df[filtered_df['loan_status'].isin(['Late (31-120 days)', 'Late (16-30 days)'])]
cols = st.columns(2)

late_30_60 = delinquency_counts[delinquency_counts['loan_status'] == 'Late (16-30 days)'].shape[0]
late_60_120 = delinquency_counts[delinquency_counts['loan_status'] == 'Late (31-120 days)'].shape[0]

cols[0].metric("Late (16-30 days) Loans", f"{late_30_60}")
cols[1].metric("Late (31-120 days) Loans", f"{late_60_120}")

# Loan Amount by Employment Length
st.subheader("Loan Amount by Employment Length")
if 'emp_length' in filtered_df.columns and 'loan_amnt' in filtered_df.columns:
    emp_length_fig = px.box(filtered_df.dropna(subset=['emp_length', 'loan_amnt']), x='emp_length', y='loan_amnt',
                            title="Loan Amount Distribution by Employment Length")
    st.plotly_chart(emp_length_fig)
else:
    st.warning("Employment length or loan amount data is missing.")

# State-wise Loan Amount Map
st.subheader("State-wise Loan Amount Map")
state_loan_data = filtered_df.groupby('addr_state', as_index=False)['loan_amnt'].sum()

# Load GeoJSON file
geojson_path = "Loan_Risk_Assessment/us-states.json"
with open(geojson_path, "r") as f:
    state_geo = json.load(f)

m = folium.Map(location=[37.8, -96], zoom_start=4)
folium.Choropleth(
    geo_data=state_geo,
    name="choropleth",
    data=state_loan_data,
    columns=["addr_state", "loan_amnt"],
    key_on="feature.id",
    fill_color="YlGnBu",
    fill_opacity=0.7,
    line_opacity=0.2,
    legend_name="Total Loan Amount ($)"
).add_to(m)
folium_static(m)

# Filter and Explore Data
st.subheader("Explore Loan Data")
st.dataframe(filtered_df)
