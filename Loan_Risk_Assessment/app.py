import streamlit as st
import pandas as pd
import plotly.express as px
import folium
from streamlit_folium import folium_static
import json

# Load datasets
customer_df = pd.read_csv("Loan_Risk_Assessment/customerdata.csv")
loan_df = pd.read_csv("Loan_Risk_Assessment/loandata.csv")
loan_reason_df = pd.read_csv("Loan_Risk_Assessment/loanreason.csv")
loan_status_df = pd.read_csv("Loan_Risk_Assessment/loanstatus.csv")
employment_df = pd.read_csv("Loan_Risk_Assessment/employmentlength.csv")

# Merge necessary dataframes
merged_df = customer_df.merge(loan_df, on='loan_id', how='inner')
merged_df = merged_df.merge(loan_reason_df, left_on='reason_code', right_on='reasoncode', how='left')
merged_df = merged_df.merge(employment_df, left_on='emp_length', right_on='emp_length', how='left')
merged_df = merged_df.merge(loan_status_df, left_on='loan_status_code_y', right_on='loan_status_code', how='left')

# Streamlit App Title
st.title("📊 Loan Data Dashboard")

# Loan Distribution Over Time
st.subheader("Loan Distribution Over Time")
merged_df['issue_date'] = pd.to_datetime(merged_df['issue_date'], errors='coerce')
merged_df = merged_df.dropna(subset=['issue_date'])  # Drop rows with invalid dates
time_series = merged_df.groupby(merged_df['issue_date'].dt.to_period('M')).size().reset_index()
time_series.columns = ['Month', 'Number of Loans']
time_series['Month'] = time_series['Month'].astype(str)  # Convert to string for plotting
fig1 = px.line(time_series, x='Month', y='Number of Loans', title='Loans Issued Over Time')
st.plotly_chart(fig1)

# Loan Amount by Reason
st.subheader("Loan Amount by Loan Reason")
loan_reason_fig = px.bar(merged_df.groupby('reason')['loan_amnt'].mean().reset_index(), x='reason', y='loan_amnt',
                         title="Average Loan Amount by Reason", labels={'loan_amnt': 'Avg Loan Amount ($)'})
st.plotly_chart(loan_reason_fig)

# Delinquency Analysis
st.subheader("Delinquency Analysis")
delinquency_counts = merged_df[merged_df['loan_status'].isin(['Late (31-120 days)', 'Late (16-30 days)'])]
delinquency_fig = px.bar(delinquency_counts.groupby('loan_status').size().reset_index(), x='loan_status', y=0,
                         title="Delinquency Status Counts", labels={'0': 'Number of Loans'})
st.plotly_chart(delinquency_fig)

# Loan Amount by Employment Length
st.subheader("Loan Amount by Employment Length")
if 'emp_length' in merged_df.columns and 'loan_amnt' in merged_df.columns:
    emp_length_fig = px.box(merged_df.dropna(subset=['emp_length', 'loan_amnt']), x='emp_length', y='loan_amnt',
                            title="Loan Amount Distribution by Employment Length")
    st.plotly_chart(emp_length_fig)
else:
    st.warning("Employment length or loan amount data is missing.")

# State-wise Loan Amount Map
st.subheader("State-wise Loan Amount Map")
state_loan_data = merged_df.groupby('addr_state', as_index=False)['loan_amnt'].sum()

# Load GeoJSON file
geojson_path = "us-states.json"
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
st.dataframe(merged_df)
